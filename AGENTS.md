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

## SwiftUI architecture and state ownership

BirthdayAgent serves as the Feature ViewModel and Agent Orchestrator for the
BirthdayPartyPilot vertical slice.

BirthdayAgent is the single observable source of truth for:

- planning,
- agent state,
- tasks,
- approvals,
- execution progress,
- failures,
- retries,
- declines,
- restart behavior,
- execution logs.

SwiftUI views render published agent state and send user intent through
explicit BirthdayAgent methods.

Views must not directly mutate task status, approvals, execution state or logs.

Do not introduce a separate ViewModel for every screen. A screen-specific
ViewModel is appropriate only when the screen owns meaningful independent
state, asynchronous work or complex presentation transformation.

Thin ViewModels that merely proxy BirthdayAgent are not permitted.

Reusable SwiftUI components and pure presentation mappings may be extracted
when they improve consistency without creating another source of truth.

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