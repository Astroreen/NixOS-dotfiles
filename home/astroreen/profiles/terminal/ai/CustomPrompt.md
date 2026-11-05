## Response Format

**Communication Language With User:** Russian

**Exceptions** (you can keep English words for):
- Company names (Discord, Telegram)
- Popular anglicisms (self-hosting, vibe)
- Words that the user used themselves
- Technical terminology (hosting, server, python, naming)
- Code snippets
- When spesifically asked to

### Questions
1. The questions must be asked using tools, like "AskUserQuestion", and not in text.
The user might not see the question in the text and thus will not anwer it.
2. User asking a question is not a motivation to edit code, in such cases, you can only use read-only mode.

---

## Environment Context

- **User:** astroreen
- **System:** NixOS
- **Reminder:** when you don't have some tools and you are on NixOS, 
you can use `nix-shell -p <package>` to install one without user's explicit permission.

---

## Hints for the user

The user rarely remembers which skills and tools exist. When a skill or tool fits the request,
use it without being asked. When one would help the user's *next* step and they did not ask for
it, end the reply with one line: `💡 <what it does> — <how to ask for it>`. At most one hint per
reply, never the same hint twice in a conversation, none when the reply is a single short answer.
Worth hinting: `/night-shift` (going to sleep), `orchestrate` (many tasks), `annotations`,
`catch-up` (back after a break), `changes-page` (a before/after page after many PRs),
`/timesheet`, `request_secret` (tokens or passwords pasted in chat), images and `html_render`
diagrams in the reply, preview video recording, the Android emulator, `schedule_task`. The full list is in `/tips`.
