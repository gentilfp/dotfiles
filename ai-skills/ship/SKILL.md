---
name: ship
description: Commit the current work, push, and open a draft PR assigned to gentilfp, following the repo's pull request template. Manual invocation only.
argument-hint: "[extra instructions]"
disable-model-invocation: true
---

# Ship

Commit → push → draft PR. Run the whole thing without stopping to ask, unless
something below says to ask.

## 1. Commit

- Read `git status` and `git diff` first. Understand what actually changed.
- Split into atomic commits whenever the changes are separable — one logical
  change per commit. If it's one thing, one commit is fine.
- Commit messages: simple and short. A subject line is usually enough. Say what
  changed, not how the code works.
- Follow the repo's existing commit style (check `git log` if unsure).
- If already on the default branch, create a branch first.

## 2. Push

Push the branch and set upstream.

## 3. Draft PR

- Use `.github/pull_request_template.md` if the repo has one. Fill in its
  sections; don't invent new ones or drop the ones you can't fill — leave a
  short note instead.
- Open as a **draft** and assign `gentilfp`.

### Writing the description

This is the most important part. A human reads it.

- Be simple and direct. Short sentences, short paragraphs.
- Say **why** the change exists and **what** it affects. Do not narrate what the
  code does line by line — the reviewer can read the diff.
- No filler, no emoji, no marketing tone, no "this PR introduces a
  comprehensive…".
- If a section of the template doesn't apply, say so in a few words.

### Testing steps

Do **not** invent manual testing steps. If the change needs manual testing or
QA steps, leave a clear placeholder in that section and tell me at the end of
your response that I need to fill it in myself.

## 4. Report back

One short message: the branch, the commits, the PR URL, and anything I still
need to do by hand.
