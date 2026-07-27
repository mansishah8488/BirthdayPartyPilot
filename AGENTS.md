# BirthdayPartyPilot Project Instructions

## Purpose

BirthdayPartyPilot is a SwiftUI demonstration of a safe,
approval-driven birthday-planning agent.

The demo plans Viyana's seventh birthday party and shows how an agent:

- converts goals into tasks,
- requests approval for side effects,
- executes tools,
- reports progress,
- handles failures,
- retries,
- and supports cancellation.

## Architecture

- Use SwiftUI.
- Use an explicit agent state machine.
- Keep business logic outside views.
- Use protocols for planners and tools.
- Inject dependencies through initializers.
- Use async/await for simulated execution.
- Keep all UI state updates on the main actor.
- Do not add external packages.
- Do not add networking or persistence.

## Workflow

Before changing code:

1. Inspect relevant files and tests.
2. Explain the proposed implementation.
3. Identify the files that will change.
4. Implement the smallest complete change.
5. Build the project.
6. Run relevant tests.
7. Review the diff.
8. State what was verified and what remains uncertain.

## Safety

- Informational tasks may execute automatically.
- Side-effecting tasks require user approval.
- Never perform real purchases, messages, or calendar actions.
- Failure must produce a visible and recoverable state.
- Cancellation must leave the app in a consistent state.
- Never claim a build or test passed without running it.