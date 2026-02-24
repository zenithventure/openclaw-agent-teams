# Bootstrap — First-Run Setup

You're the first agent to wake up in a freshly installed team. Welcome! This file walks you through the one-time setup that gets everyone configured.

Your identities are already set (SOUL.md, IDENTITY.md) — this is just about connecting the team to the human.

---

## Step 1: Configure USER.md

Every agent has a `USER.md` file in their workspace. Right now, they're all templates. You need to fill them in.

Ask the human:
- **Name:** What should the agents call you?
- **Timezone:** What timezone are you in? (e.g., `America/New_York`, `Europe/London`, `Asia/Tokyo`)
- **Email:** What email should we associate with your account? (optional)
- **Communication style:** Do you prefer concise updates or detailed explanations?
- **Availability:** What hours are you typically available? Any days off?
- **Preferences:** Anything else the agents should know? (e.g., "I hate emojis", "Always explain your reasoning", "Don't message me before 9am")

Write the answers into `USER.md` in your workspace. Then copy the same content to every other agent's `USER.md`:
- Check each `workspace-*/USER.md` and update them all to match

If the human doesn't want to answer everything now, fill in what you have and note the rest as "TBD."

---

## Step 2: Configure shared/VISION.md

Open `shared/VISION.md`. It has a template structure with placeholder text.

Ask the human:
- **Mission:** What is this team's primary mission? What are you trying to accomplish?
- **Success criteria:** How will you know when you've succeeded? What are the concrete deliverables?
- **Constraints:** Any hard boundaries? Budget limits, technology requirements, deadlines?
- **Priority order:** When trade-offs arise, what matters most?
- **Context:** Any background the agents should know? Industry, existing systems, prior attempts?

Help the human write these into `shared/VISION.md`. Don't just dump their raw answers — help structure them clearly. The Vision is the single most important document for the team.

If the human isn't ready for a full Vision yet, help them write even a one-line mission statement. Something is better than nothing.

---

## Step 3: Verify

Do a quick sanity check:
- [ ] `USER.md` is filled in across all agent workspaces
- [ ] `shared/VISION.md` has at least a mission statement
- [ ] The human knows they can edit the Vision anytime

Let the human know: "Setup is done. Your agents will read these files at the start of every session. You can update USER.md or VISION.md anytime — changes take effect on the next session."

---

## Step 4: Self-Destruct

You're done here. Delete this file:

```
trash shared/BOOTSTRAP.md
```

You don't need a bootstrap anymore. Future sessions will start with the normal boot sequence from `shared/STANDARDS.md`.
