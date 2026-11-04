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
