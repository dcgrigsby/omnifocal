# Recommendations for a Factory Brainstorming Skill

## Problem Statement

The existing brainstorming skill focuses on product design — what to build, how components interact, what the acceptance criteria are. It does not address **factory design** — how to break the work into units that an LLM-driven pipeline can reliably complete.

This gap caused 5 failed pipeline runs on the OmniFocal project before we identified the root causes. All of the failures were preventable at brainstorming time.

## Recommended Additions

### 1. Decomposition by File Type Diversity

**The rule:** If a single implementation node produces more than 2-3 distinct file types (e.g., Go source + XML plist + shell scripts), split it into one node per file type family.

**Why:** LLMs context-switch poorly between languages in a single generation. A node asked to write Go code AND shell scripts will prioritize the primary code and skip or stub the scripts. With `auto_status=true`, this registers as success.

**Brainstorming question:** "For each component, what distinct file types will it produce? If the answer is more than 2-3, plan separate implementation nodes."

### 2. Observable Success Criteria

**The rule:** Before finalizing the design, ask "What does success look like from the outside?" — not in terms of tests passing, but in terms of observable behavior a human would notice.

**Why:** The OmniFocal pipeline "passed" multiple times with hollow tests. If we had asked "what should I see when this works?" during brainstorming, the answer would have been "OmniFocus should show activity, the server process should be running, Claude Code should produce real task names." That framing makes hollow tests obvious.

**Brainstorming question:** "If this is working correctly, what would you observe on the machine? What processes are running? What data appears? What changes?"

### 3. Evidence Content Assertions

**The rule:** For every integration test scenario, specify what the evidence should *contain* — not just that it exists.

**Why:** "Verify 200 response" is not enough. A 200 response with an empty body or "null" is technically a 200 but proves nothing. The DoD should say "response body must be parseable JSON containing at least one object with a `name` field."

**Brainstorming question:** "For each test, what would a valid response look like? What fields or patterns prove this is real data from the target system, not a stub?"

### 4. Smoke Testing Before Pipeline Launch

**The rule:** Before the first pipeline run, extract the most complex implementation node's prompt and run it manually against the target model. Verify the model produces all expected deliverables.

**Why:** The first pipeline run should be a validation run, not a production run. If the model can't complete the task in isolation, it won't complete it inside the pipeline either. A 5-minute manual test saves hours of failed pipeline runs.

**Brainstorming question:** "Which implementation node is the most complex? Can we test its prompt manually before launching?"

### 5. Model-Task Fitness

**The rule:** Match models to tasks based on known strengths (e.g., from a weather report or benchmark). Don't use the default model for everything.

**Why:** gpt-5.3-codex couldn't handle dense multi-file prompts but excels at focused code generation. claude-opus-4.6 handled the same prompts easily. gpt-5.4 is better for planning and architectural critique. Using the right model for each task type reduces failures.

**Brainstorming question:** "Given the weather report, which model should handle planning? Implementation? Verification? Review?"

### 6. Auto-Status Risk Assessment

**The rule:** Identify which nodes have `auto_status=true` and evaluate whether silent success is safe. For implementation nodes that produce multiple files, `auto_status=true` is dangerous — the model may write the primary file and exit, claiming success without producing supporting files.

**Why:** `auto_status=true` means "if the model doesn't explicitly fail, assume success." This is fine for synthesis nodes that write one document. It's dangerous for implementation nodes where partial completion looks like success.

**Brainstorming question:** "Which nodes could partially complete and still appear successful? Should those require explicit success verification?"

## Summary

The factory brainstorming skill should add these questions to the design phase:

1. How should the work be decomposed for the factory? (file type diversity)
2. What does success look like from the outside? (observable criteria)
3. What should test evidence contain? (content assertions)
4. Can we smoke test the hardest node before launching? (manual validation)
5. Which model fits each task? (model-task fitness)
6. Where is auto_status dangerous? (partial completion risk)

These questions bridge the gap between "what are we building?" and "can the factory actually build it?"
