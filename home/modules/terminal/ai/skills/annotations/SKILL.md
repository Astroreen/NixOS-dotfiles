# Annotations

The owner clicked through the app in the T3 preview and left a batch of annotations
(`t3-context://v1/preview-annotation/...` links), often 10 to 20 in one message, plus free text.

## Steps

1. **Read every annotation in full**, with its screenshot, page and element. The link label is cut
   off; the meaning is in the full text. Read the free text around the links too.
2. **Classify each one** into exactly one bucket:
   - **bug**: something broken or wrong;
   - **design**: layout, spacing, wording, order of controls;
   - **question**: the owner asks why or how something works;
   - **decision**: the owner chooses between behaviours or changes a rule.
   Annotations about something outside this thread's topic get a GitHub issue instead of a fix
   (the owner asked for this: "сделай отдельное ишью, это не твоя задача в этом треде").
3. **Answer questions first**, in one message. If an answer may change what the owner wants,
   stop there and wait for them. Otherwise continue.
4. **Group** bugs, design items and decisions by screen or module, so each group is one PR that
   does not overlap with another. Several groups → the `orchestrate` skill; one small group → fix
   it yourself.
5. **Check each fix on the same screen in the preview** before calling it done. Compare it with the
   annotation text, item by item.
6. **Report** as a table: annotation (short) → bucket → what was done → PR. Every annotation
   appears in it.

Done means: every annotation in the batch is answered, fixed and checked in the preview, or turned
into an issue, and the table shows which.
