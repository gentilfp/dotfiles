---
name: zok-decompose
description: Turn a large or vague idea into a short spec page and ordered backlog cards in a Zoku project. Each card is then planned with zok-plan.
argument-hint: "<PROJECT> <idea or epic>"
disable-model-invocation: true
---

# Zoku Decompose

Split one idea into cards. Do not plan or implement them.

Read [shared rules](../zok-plan/zok-common.md). Require a project name or prefix; ask if missing. Never guess a project.

1. Read the idea and any context the user gives. Look at the relevant code when it changes scope.
2. Ask only questions that change scope, order, or acceptance criteria. Ask them in one round, each with your recommended answer.
3. Draft the spec: problem, in scope, out of scope, success criteria, constraints, open decisions. Do not invent requirements; list unknowns as open decisions.
4. Draft 3 to 7 cards, ordered by dependency and then risk. Each card should be useful on its own. For each card: a title, a one-line goal, acceptance criteria, and `Depends on:` when another card must come first.
5. Show the spec and the cards. Wait for approval.
6. On approval, save the spec with Zoku MCP `create_page`, titled `Spec: <idea>`. Create each card in order with `create_card` in `backlog`. Put the goal, criteria, and dependency in `description`. Leave `prompt` empty.
7. Report the page title and the card identifiers in order. Next step: `zok-plan` on the first card.

Do not create cards before approval. Do not write implementation instructions.
