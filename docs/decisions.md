# Architecture Decisions

## Deterministic planner first

The initial planner is deterministic rather than LLM-backed.

This allows planning, approval, execution, failure recovery, and
cancellation to be tested without model variability.

A future LLM planner can be added behind the same protocol.

## Explicit approval boundary

Every task declares whether it is informational or requires approval.

The agent cannot execute side-effecting tasks until the user explicitly
approves them.

## Feature-level ViewModel

BirthdayAgent currently serves as both the agent orchestrator and the
feature-level ViewModel.

This is intentional for the focused BirthdayPartyPilot vertical slice. The
three primary screens display different projections of the same task workflow,
rather than owning independent data or asynchronous operations.

Creating PartyBriefViewModel, PlanReviewViewModel and ExecutionViewModel would
introduce forwarding layers and risk duplicate state without establishing a
meaningful responsibility boundary.

The current flow is:

SwiftUI user intent
→ BirthdayAgent
→ planner and tool dependencies
→ observable agent state
→ SwiftUI rendering

A separate BirthdayPartyViewModel should be introduced when:

- presentation transformation becomes substantial,
- the UI combines multiple domain services,
- screens gain independent asynchronous workflows,
- navigation coordination becomes complex,
- or BirthdayAgent should become UI-framework independent.