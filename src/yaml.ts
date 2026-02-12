/**
 * Minimal YAML parser for the subset used in workflow.yml.
 * Handles: scalars, literal blocks (|), folded blocks (>), sequences of maps,
 * nested maps, inline arrays [a, b], comments, quoted strings.
 */

interface Line {
  indent: number;
  raw: string;
  text: string;
}

function tokenize(src: string): Line[] {
  const lines: Line[] = [];
  for (const raw of src.split('\n')) {
    const stripped = raw.replace(/#(?![{]).*$/, ''); // remove comments (but not inside templates)
    if (/^\s*#/.test(raw) || stripped.trim() === '') continue;
    const match = stripped.match(/^(\s*)/);
    lines.push({ indent: match ? match[1].length : 0, raw, text: stripped.trimEnd() });
  }
  return lines;
}

function unquote(s: string): string {
  s = s.trim();
  if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
    return s.slice(1, -1);
  }
  return s;
}

function parseInlineArray(s: string): string[] {
  s = s.trim();
  if (!s.startsWith('[') || !s.endsWith(']')) return [];
  return s.slice(1, -1).split(',').map(item => unquote(item.trim())).filter(Boolean);
}

function parseScalar(value: string): string | number | boolean | null {
  const v = value.trim();
  if (v === 'true') return true;
  if (v === 'false') return false;
  if (v === 'null' || v === '~' || v === '') return null;
  if (/^-?\d+$/.test(v)) return parseInt(v, 10);
  if (/^-?\d+\.\d+$/.test(v)) return parseFloat(v);
  return unquote(v);
}

export function parseYaml(src: string): Record<string, unknown> {
  const lines = tokenize(src);
  let pos = 0;

  function collectBlock(baseIndent: number, style: '|' | '>'): string {
    const parts: string[] = [];
    while (pos < lines.length && (lines[pos].indent > baseIndent || lines[pos].text.trim() === '')) {
      if (lines[pos].text.trim() === '') {
        parts.push('');
      } else {
        parts.push(lines[pos].text.slice(baseIndent + 2));
      }
      pos++;
    }
    // remove trailing empty lines
    while (parts.length > 0 && parts[parts.length - 1] === '') parts.pop();
    return style === '|' ? parts.join('\n') + '\n' : parts.join('\n').replace(/\n(?!\n)/g, ' ') + '\n';
  }

  function parseMap(minIndent: number): Record<string, unknown> {
    const result: Record<string, unknown> = {};
    while (pos < lines.length) {
      const line = lines[pos];
      if (line.indent < minIndent) break;

      const trimmed = line.text.trim();
      // sequence item at this level
      if (trimmed.startsWith('- ')) break;

      // key: value
      const kvMatch = trimmed.match(/^([\w][\w.-]*)\s*:\s*(.*)$/);
      if (!kvMatch) { pos++; continue; }

      const key = kvMatch[1];
      const rest = kvMatch[2].trim();
      const keyIndent = line.indent;
      pos++;

      if (rest === '|') {
        result[key] = collectBlock(keyIndent, '|');
      } else if (rest === '>') {
        result[key] = collectBlock(keyIndent, '>');
      } else if (rest.startsWith('[')) {
        result[key] = parseInlineArray(rest);
      } else if (rest === '' || rest === undefined) {
        // nested map or sequence
        if (pos < lines.length && lines[pos].indent > keyIndent) {
          if (lines[pos].text.trim().startsWith('- ')) {
            result[key] = parseSequence(lines[pos].indent);
          } else {
            result[key] = parseMap(lines[pos].indent);
          }
        } else {
          result[key] = null;
        }
      } else {
        result[key] = parseScalar(rest);
      }
    }
    return result;
  }

  function parseSequence(minIndent: number): unknown[] {
    const result: unknown[] = [];
    while (pos < lines.length) {
      const line = lines[pos];
      if (line.indent < minIndent) break;
      const trimmed = line.text.trim();
      if (!trimmed.startsWith('- ')) break;

      const after = trimmed.slice(2).trim();
      pos++;

      // Inline scalar sequence item
      if (after && !after.includes(':')) {
        result.push(parseScalar(after));
        continue;
      }

      // Map item starting on same line as dash: "- key: value"
      const inlineKv = after.match(/^([\w][\w.-]*)\s*:\s*(.*)$/);
      if (inlineKv) {
        const item: Record<string, unknown> = {};
        const itemKey = inlineKv[1];
        const itemRest = inlineKv[2].trim();

        if (itemRest === '|') {
          item[itemKey] = collectBlock(line.indent, '|');
        } else if (itemRest === '>') {
          item[itemKey] = collectBlock(line.indent, '>');
        } else if (itemRest.startsWith('[')) {
          item[itemKey] = parseInlineArray(itemRest);
        } else if (itemRest === '') {
          if (pos < lines.length && lines[pos].indent > line.indent) {
            if (lines[pos].text.trim().startsWith('- ')) {
              item[itemKey] = parseSequence(lines[pos].indent);
            } else {
              item[itemKey] = parseMap(lines[pos].indent);
            }
          } else {
            item[itemKey] = null;
          }
        } else {
          item[itemKey] = parseScalar(itemRest);
        }

        // Continue parsing remaining keys of this map item
        while (pos < lines.length && lines[pos].indent > line.indent) {
          const subLine = lines[pos];
          const subTrimmed = subLine.text.trim();
          if (subTrimmed.startsWith('- ')) break;
          const subKv = subTrimmed.match(/^([\w][\w.-]*)\s*:\s*(.*)$/);
          if (!subKv) { pos++; continue; }

          const sk = subKv[1];
          const sv = subKv[2].trim();
          const subIndent = subLine.indent;
          pos++;

          if (sv === '|') {
            item[sk] = collectBlock(subIndent, '|');
          } else if (sv === '>') {
            item[sk] = collectBlock(subIndent, '>');
          } else if (sv.startsWith('[')) {
            item[sk] = parseInlineArray(sv);
          } else if (sv === '') {
            if (pos < lines.length && lines[pos].indent > subIndent) {
              if (lines[pos].text.trim().startsWith('- ')) {
                item[sk] = parseSequence(lines[pos].indent);
              } else {
                item[sk] = parseMap(lines[pos].indent);
              }
            } else {
              item[sk] = null;
            }
          } else {
            item[sk] = parseScalar(sv);
          }
        }
        result.push(item);
      } else if (!after) {
        // Nested content under bare dash
        if (pos < lines.length && lines[pos].indent > line.indent) {
          if (lines[pos].text.trim().startsWith('- ')) {
            result.push(parseSequence(lines[pos].indent));
          } else {
            result.push(parseMap(lines[pos].indent));
          }
        }
      } else {
        result.push(parseScalar(after));
      }
    }
    return result;
  }

  return parseMap(0);
}
