# BirthdayPartyPilot Venue Prompt Experiment

## Objective

Compare a vague prompt and a constrained prompt for adding an
approval-required venue-confirmation task.

## Controlled variables

- Baseline branch: `features/venue-confirmation-task-vague-prompt`
- Cursor model: GPT-5.6 Sol
- Cursor mode: Agent
- XcodeBuildMCP: Ready
- Scheme: `BirthdayPartyPilot`
- Simulator: iPhone 17, iOS 26.5
- Baseline build result: Passed
- Baseline test result: 24 passed, 0 failed, 0 skipped
- Existing planner task count: 5
- Experiment date: July 28, 2026

## Required feature

- Task title: Confirm venue reservation details
- Category: venue
- Approval: required
- Initial status: pending

Expected order:

1. Calculate cake servings
2. Create food quantity checklist
3. Prepare party-favor shopping list
4. Confirm venue reservation details
5. Draft RSVP reminder
6. Prepare cake pickup reminder

## Attempt A — Vague prompt

- Branch: `features/venue-confirmation-task-vague-prompt`
- Start time: July 28, 2026, 6:14 PM UTC-7
- End time: July 28, 2026, 6:20 PM UTC-7
- Prompt: “Add a venue-confirmation task that requires approval”
- Files proposed:
  - `BirthdayPartyPilot/Planning/DeterministicBirthdayPlanner.swift`
  - `BirthdayPartyPilotTests/BirthdayAgentExecutionTests.swift`
  - `BirthdayPartyPilotTests/DeterministicBirthdayPlannerTests.swift`
  - `BirthdayPartyPilotUITests/BirthdayPartyPilotUITests.swift`
- Files changed: Same four files
- Unrelated files changed: None
- Tests proposed: Planner, execution, full unit suite, and end-to-end UI flow
- Tests added or updated: Planner expectations, execution ordering/status
  expectations, UI task and decline flow
- First build result: Passed
- First focused-test result: 1 passed
- Full test-suite result: 24 passed, 0 failed, 0 skipped
- Correction cycles: 0
- Manual guidance required: Yes—the vague prompt omitted required task ordering
- Architecture concerns: Tests rely heavily on fixed task indices
- Final result: Task properties were correct, but placement was sixth. The
  required placement was fourth, so the implementation did not fully match.

## Attempt B — Constrained prompt

- Branch: `features/venue-confirmation-task-constrained-prompt`
- Start time: July 28, 2026, 6:42 PM UTC-7
- End time: July 28, 2026, 6:47 PM UTC-7
- Prompt: Add “Confirm venue reservation details” after the favor task,
  category venue, approval required, using the generic approval flow
- Files proposed:
  - `BirthdayPartyPilot/Planning/DeterministicBirthdayPlanner.swift`
  - `BirthdayPartyPilotTests/DeterministicBirthdayPlannerTests.swift`
  - `BirthdayPartyPilotTests/BirthdayAgentExecutionTests.swift`
  - `BirthdayPartyPilotUITests/BirthdayPartyPilotUITests.swift`
- Files changed: Same four files
- Unrelated files changed: None
- Tests proposed: Planner ordering, execution/approval flow, UI flow, complete
  suite
- Tests added or updated: Planner, execution, and UI expectations
- First build result: Passed
- First focused-test result: 3 passed
- Full test-suite result: 28 passed, 0 failed, 0 skipped
- Correction cycles: 0
- Manual guidance required: None
- Architecture concerns: Existing tests rely heavily on task indices
- Final result: Passed; task was fourth and used the generic approval flow

## Comparison

| Measure | Vague | Constrained |
|---|---:|---:|
| Production files changed | 1 | 1 |
| Test files changed | 3 | 3 |
| Unrelated changes | None | None |
| Generic architecture reused | Yes | Yes |
| Special-case venue logic added | No | No |
| Focused tests included | Yes — 1 passed | Yes — 3 passed |
| First build passed | Yes | Yes |
| Full suite passed | Yes — 24 passed | Yes — 28 passed |
| Correction cycles | 0 | 0 |
| Manual guidance required | Yes — task order | No |
| Verified completion time | 6 minutes | 5 minutes |

## Evidence-based conclusions

- Both attempts changed one production file and three test files.
- Both reused the generic approval architecture and avoided venue-specific
  agent, tool, and UI logic.
- Both passed their first build and reported no unrelated changes.
- The vague prompt omitted deterministic ordering, which required manual
  guidance and initially placed the new task sixth.
- The constrained prompt produced the required fourth-position ordering
  without clarification.
- Focused verification increased from one passing test in the vague attempt to
  three passing tests in the constrained attempt.
- The recorded suite totals are not directly equivalent: Attempt A recorded 24
  tests, while Attempt B recorded the complete 28-test unit/UI suite.

## Experiment conclusion

The production implementations were nearly identical. Both attempts changed
one production file, reused the generic architecture, avoided unrelated
changes, and passed the build and recorded test suite.

The main difference was not code quality or implementation size.

The vague prompt required one manual clarification about deterministic task
order and initially added one focused test. The constrained prompt required no
manual clarification and added three focused tests covering the planner
contract and approval behavior.

This suggests that the repository-level context in `AGENTS.md`, Cursor rules,
architecture decisions, and the existing test suite already constrained the
model effectively. The task-specific constrained prompt added value primarily
by making ordering and verification expectations explicit.

The constrained workflow therefore improved predictability and reduced
supervision, but it did not produce a dramatically different implementation
for this relatively small, well-supported change.

## Interview explanation

Both prompts produced clean code because my repository instructions and
architecture already supplied strong persistent context.

- The constrained prompt did not reduce the production diff, but it eliminated
  one clarification and increased focused test coverage from one test to three.
- My takeaway was that good AI-assisted development is not only about writing
  longer prompts. Repository-level context establishes consistent boundaries,
  while task-level prompts should focus on ambiguities, invariants, and
  verification.
