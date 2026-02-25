# Installation

## Requirements

- Git
- Python 3 (for JSON parsing in scripts)
- `gh` CLI (for PR creation in report phase)

## Claude Code

If a plugin marketplace entry is available:

```bash
/plugin install pathfinder
```

Otherwise, clone and register manually:

```bash
git clone https://github.com/srhenrybot-hub/superpowers.git ~/.pathfinder
```

Add to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "enabledPlugins": {
    "pathfinder": true
  }
}
```

## OpenClaw

Symlink to the skills directory:

```bash
git clone https://github.com/srhenrybot-hub/superpowers.git ~/.pathfinder
ln -s ~/.pathfinder ~/.npm-global/lib/node_modules/openclaw/skills/pathfinder
```

## Any Project (Git Hooks)

To enable Pathfinder's git hooks in a project:

```bash
cd your-project
git config core.hooksPath /path/to/pathfinder/.githooks
```

This activates:
- **pre-push:** Blocks push to main/master
- **pre-commit:** Enforces phase ordering
- **post-commit:** Auto-syncs state.json

## Verify Installation

Start a conversation with your coding agent and type `/survey`. The agent should invoke `pathfinder:surveying` and begin the expedition workflow.

Or check that the session-start hook loads:

```bash
bash /path/to/pathfinder/hooks/session-start
# Should output JSON with using-pathfinder skill content
```

## Updating

Pull from upstream to get Superpowers updates, then rebase the Pathfinder branch:

```bash
cd ~/.pathfinder
git fetch upstream
git rebase upstream/main
```
