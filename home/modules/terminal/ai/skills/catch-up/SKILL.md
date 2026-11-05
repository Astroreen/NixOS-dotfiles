# Catch-up

The owner comes back after hours or days and has forgotten what this thread did. Rebuild the
picture from evidence, not from memory: the conversation, the PRs (`gh pr list --state all
--author @me`), commits on the branch, linked issues, and the project memory.

## The report (Russian, one section per task)

For each task, short but concrete:

1. **What was asked**: one sentence in the owner's words.
2. **What was done**: PR link, its state (merged / open / red), and where it is deployed.
3. **Decisions taken** without the owner, each with its reason.
4. **How it works now** for the people who use it: which screen, which button, what happens.
   Name screens the way the UI names them.
5. **What waits for the owner**, if anything.

End with a list of everything that waits for the owner, most urgent first.

## Visual mode

When the owner asks to see changes (e.g. "покажи картинками", "до и после"), add screenshots: open
each changed screen in the preview on the old code (`main` or the base branch) and on the new
code, save both as PNG files, and put them in the reply as Markdown images with absolute paths:
`![до](/abs/path/before.png) ![после](/abs/path/after.png)`. Put a diagram (flow, data model) in
the reply with `html_render` when a picture explains the change better than text. Images never go
into the repository.

Many changes (a whole branch, a batch of PRs) or a document the owner will keep: build it with the
`changes-page` skill (a PDF) instead of images in the reply.

Done means: every task of the thread has all five points, and the owner's waiting list is at the
end.
