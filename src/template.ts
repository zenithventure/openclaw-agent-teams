/**
 * Resolve {{variable}} placeholders in a template string against a context object.
 * Case-insensitive fallback; missing keys become [missing: key].
 */
export function resolveTemplate(template: string, context: Record<string, string>): string {
  return template.replace(/\{\{(\w+)\}\}/g, (_match, key: string) => {
    if (key in context) return context[key];
    const lower = key.toLowerCase();
    for (const k of Object.keys(context)) {
      if (k.toLowerCase() === lower) return context[k];
    }
    return `[missing: ${key}]`;
  });
}
