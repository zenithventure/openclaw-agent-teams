# Installing Agent Teams on DigitalOcean

This guide walks you through deploying any OpenClaw agent team on a DigitalOcean droplet.

## Prerequisites

- A DigitalOcean account
- Basic familiarity with SSH and the command line
- ~5 minutes

## Step 1: Create a Droplet

1. Go to [DigitalOcean](https://cloud.digitalocean.com)
2. Create a new **Ubuntu 24.04** droplet:
   - **Basic (Personal):** 4GB RAM, 2 CPU — for experimenting
   - **Small Team:** 8GB RAM, 4 CPU — for production use
3. SSH into your droplet:
   ```bash
   ssh root@YOUR_DROPLET_IP
   ```

## Step 2: Install OpenClaw

Follow the [OpenClaw installation guide](https://docs.openclaw.ai) to install OpenClaw on your droplet.

## Step 3: Install a Team

Pick a team and run its one-line installer:

### Product Builder
```bash
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/product-builder/setup.sh
```

### Accountant
```bash
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/accountant/setup.sh
```

### Recruiter
```bash
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/recruiter/setup.sh
```

### Real Estate
```bash
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/real-estate/setup.sh
```

### Modernizer
```bash
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/modernizer/setup.sh
```

### Operator
```bash
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/operator/setup.sh
```

## Step 4: Configure

1. **Set your API key** in `~/.openclaw/.env`
2. **Edit your vision** — `~/.openclaw/shared/VISION.md` with your business context
3. **Set your info** — Update `USER.md` in each agent's workspace
4. **Start:** `openclaw start`

## Troubleshooting

### Agent isn't responding
- Make sure you've set your API key in `~/.openclaw/.env`
- Check that `~/.openclaw/shared/VISION.md` has meaningful content
- Send a simple message to test: "Hello"

### Want more control?
Edit the team's files to adjust agent behavior:
- `~/.openclaw/shared/VISION.md` — business context
- `~/.openclaw/workspace-*/SOUL.md` — agent personality
- `~/.openclaw/shared/skills/*` — agent capabilities

## Questions?

See the full documentation: https://docs.openclaw.ai
