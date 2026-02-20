# Installing Agent Teams on DigitalOcean

This guide walks you through deploying any OpenClaw agent team on a DigitalOcean droplet.

## Prerequisites

- A DigitalOcean account
- Basic familiarity with SSH and the command line
- ~5 minutes

## Step 1: Deploy the OpenClaw Droplet

1. Go to [DigitalOcean Marketplace](https://marketplace.digitalocean.com/apps/openclaw)
2. Click **"Create OpenClaw Droplet"**
3. Choose your region and droplet size:
   - **Basic (Personal):** 4GB RAM, 2 CPU — for experimenting
   - **Small Team:** 8GB RAM, 4 CPU — for production use
4. Click **Create Droplet** and wait for it to provision (~1-2 minutes)

## Step 2: Access Your Droplet

Copy your droplet's IP address from the DigitalOcean dashboard, then SSH in:

```bash
ssh root@YOUR_DROPLET_IP
```

You'll see a welcome message with setup instructions.

## Step 3: Run the Team Installer

Choose a team and run its installer. The installer will:
- Verify you're on a DO OpenClaw droplet
- Unlock execution policies
- Inject team configuration into the sandbox
- Deploy all 4 agents

### Option A: Accountant
```bash
curl -sL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/accountant/do-team-install.sh | bash -s -- accountant
```

### Option B: Recruiter
```bash
curl -sL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/recruiter/do-team-install.sh | bash -s -- recruiter
```

### Option C: Real Estate
```bash
curl -sL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/real-estate/do-team-install.sh | bash -s -- real-estate
```

The installer will take ~1-2 minutes. You'll see colored output showing each step:
- ✓ Environment verification
- ✓ Policy unlocking
- ✓ Configuration injection
- ✓ Service restart

## Step 4: Access Your Dashboard

Once the installer completes, open your browser to:
```
https://YOUR_DROPLET_IP
```

Accept the self-signed certificate warning (this is normal for fresh droplets).

You should see the OpenClaw dashboard with your agents ready.

## Step 5: Configure Messaging

Choose how your agents should communicate:

### Telegram (Recommended)
1. Create a Telegram bot via [@BotFather](https://t.me/BotFather)
2. From the dashboard, click **Channels → Add Channel → Telegram**
3. Paste your bot token
4. Scan the QR code from your phone

### WhatsApp
1. From the dashboard, click **Channels → Add Channel → WhatsApp**
2. Scan the QR code with WhatsApp on your phone

### Discord, Slack, Signal, etc.
1. From the dashboard, click **Channels → Add Channel**
2. Select your platform and follow the prompts

## Step 6: Start Using Your Agents

Edit the team's `shared/VISION.md` to define your business context:

```bash
nano /workspace/shared/VISION.md
```

Then send a message to your agent through your messaging app! For example:

**Accountant team:**
> "I just got a bank statement with 50 transactions. Can you categorize them?"

**Recruiter team:**
> "We're hiring a senior engineer. What questions should we ask?"

**Real Estate team:**
> "Here's a property I'm evaluating. What's your risk assessment?"

## Governance: What You Unlocked

When the installer ran, it unlocked three execution policies. Here's what each one means:

**`tools.exec.host = gateway`**
- Agents need somewhere to run commands
- On a headless server (no terminal), this is the OpenClaw gateway
- Without this, commands would hang or fail silently

**`tools.exec.ask = off`**
- By default, agents ask for approval before running tools
- On a VPS, no one is there to approve
- Turning this off means commands run automatically (which is what you want)
- This is safe because the `openclaw` user already can't escalate to root

**`tools.exec.security = full`**
- By default, agents are locked down to minimal capabilities
- "Full" means they can make network calls, read/write files (within their sandbox), run shell commands
- Still can't touch system files or escape the sandbox
- This is the practical level where agents can actually do useful work

**The Sandbox Boundary**
- Agents run as the `openclaw` user (not root)
- Inside a Docker container
- Can't modify `/opt/openclaw.env` or other system config
- Can't escalate privileges or access other users' data
- Can read/write only within their workspace

This is security by architecture, not by promises.

## Troubleshooting

### "ERROR: /opt/openclaw-cli.sh not found"
You're not on a DigitalOcean OpenClaw droplet. Make sure you deployed from the Marketplace, not a custom image.

### Dashboard won't load
- Give it 30 seconds after the installer finishes
- Check `systemctl status openclaw` to see if the service is running
- Check logs: `journalctl -u openclaw -n 50`

### Agent isn't responding
- Make sure you've connected a messaging channel (Telegram, WhatsApp, etc.)
- Check that your VISION.md has meaningful content
- Send a simple message to test: "Hello"

### Want more control?
If you need to adjust agent behavior, edit the team's files:
- `shared/VISION.md` — business context
- `agents/*/SOUL.md` — agent personality
- `shared/skills/*` — agent capabilities

Restart the service to apply changes:
```bash
systemctl restart openclaw
```

## Next Steps

- **Learn more:** Read your team's README in the [openclaw-agent-teams repo](https://github.com/zenithventure/openclaw-agent-teams)
- **Customize:** Edit VISION.md to reflect your actual business
- **Deploy more teams:** You can run multiple teams on the same droplet if you scale up the droplet size
- **Monitor:** Use the dashboard to see agent activity and logs

## Questions?

See the full documentation: https://docs.openclaw.ai
