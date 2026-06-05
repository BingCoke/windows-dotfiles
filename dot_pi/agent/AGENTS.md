Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.


## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
- Before writing or modifying code, first think through the approach and communicate it to the user. Do not start editing code immediately after thinking. Wait for explicit user confirmation that the approach is acceptable, unless the user has clearly instructed you to "directly modify", "直接修改", or otherwise proceed without confirmation.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Context Management & Subagent Delegation

**Keep the main context focused on orchestration, not implementation details.**

For complex, multi-step tasks or when context is growing large, proactively delegate independent work to subagents using the `pi-subagents` skill:

- **Prefer async by default.** Launch subagents with `async: true` unless you have a specific reason to block.
- **Delegate implementation, not orchestration.** Use `worker` for implementation, `reviewer` for code review, `scout` for codebase recon, `researcher` for external research, `planner` for plans. The parent owns decisions.
- **Parallelize independent reads.** Run multiple scouts, researchers, or reviewers concurrently. Keep writes single-threaded.
- **Review after implementation.** After a worker finishes, launch fresh-context reviewers before accepting the result.
- **Escalate, don't guess.** If a subagent encounters an unapproved decision, it should coordinate back — don't let it invent answers.
- **Don't run subagents for trivial tasks.** A one-line edit or simple question doesn't need delegation. Use judgment.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.




