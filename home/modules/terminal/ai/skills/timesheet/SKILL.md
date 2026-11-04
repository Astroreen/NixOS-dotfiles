# Timesheet

The owner logs freelance hours in an `.xlsx` file (e.g. `~/Downloads/v2 Время проведенное за
работой.xlsx`). They enter the time; you fill in what was done.

## The one rule

**The hours, dates and start/end times the owner wrote are correct. Never change them**, not even
when the work found looks larger or smaller. You write only the feature and comment cells.
The tasks/PRs which were done in between the sessions, should be added to the comment of the first session. 

## Steps

1. Open the file the owner attached or named, and find the rows (sessions) to fill: the ones whose
   feature or comment cells are empty, or the row numbers the owner named.
2. Read the existing filled rows: their wording, length, language and how features are listed.
   Your text matches that style.
3. For each session's date and time range, collect the work done: merged and opened PRs
   (`gh pr list --state all --search "created:<date>"` or `merged:<date>`), commits
   (`git log --since --until --all`), and T3Code threads of that time (the T3 database or
   `t3_thread_search`). Use every project the owner worked on for that client.
4. Fill the cells: the features, and a comment like the previous ones. Add features the owner
   forgot to rows that already have text, without removing theirs.
5. Save in place, in the same file the owner uses (on the machine where it lives; over ssh if it is
   on another host). Keep a backup copy next to it first.
6. Show the owner the rows you changed, cell by cell.

Done means: every target row has its features and comment, every hour value is identical to before,
and the owner saw the diff.
