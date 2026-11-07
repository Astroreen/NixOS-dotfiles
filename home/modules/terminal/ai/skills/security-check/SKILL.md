# security-check

A focused security pass on a change. Run it when the diff touches any of: who may do what
(roles, permissions, ownership checks), login or sessions, tokens and secrets, file upload,
download or paths, agent/MCP tools and anything they can call, public or shared pages, webhooks,
outbound requests, emails, or any data that leaves the system.

Read the repo's `AGENTS.md` / `CLAUDE.md` first: it says where permissions are checked and what
the project counts as sensitive. Prefer a fresh context (sub-agent or separate thread) given the
diff and those rules only.

## What to look for

1. **Side doors.** A new route, endpoint, tool, job, page or export that reaches data without the
   check the main path has. Compare it with the nearest existing path that does the same thing.
2. **Missing or wrong permission check.** Checked in the UI only; checked for "logged in" but not
   "owns this record"; an ID from the request trusted without a lookup scoped to the caller; a
   role name typo; a default that allows.
3. **Injection.** User or model text reaching SQL, shell, file paths (`../`), HTML, templates,
   URLs, regexes, or another agent's prompt without escaping or an allow-list.
4. **Secrets.** Keys, tokens, passwords in code, config, logs, error messages, the client bundle,
   or test fixtures; secrets passed to a third party that does not need them.
5. **Leaving the system.** Emails, webhooks, uploads, outbound HTTP, public links: who triggers
   them, can it be repeated or aimed at another target (SSRF, open redirect), what personal data
   goes out.
6. **Agent tools.** What can a tool do if the model is told to by text it read (a web page, a
   file, a comment)? Destructive or outbound actions need a check the model cannot talk past.

Each finding needs a concrete attack: who (anonymous, other user, low role, injected text) does
what, and gets what. Verify it against the code before reporting; drop theoretical ones.

## Output

```
Scope:    <which of the areas above the diff touches>
Findings: <severity> <file:line> — <attack: who → what → result> — fixed | open: <reason>
Checked:  <areas reviewed with nothing found>
```

An open high-severity finding blocks the PR until fixed or the owner accepts it in writing.
