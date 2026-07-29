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

## BirthdayAgent as the Feature ViewModel

BirthdayAgent currently serves as both the agent orchestrator and the
feature-level ViewModel.

This is intentional because PartyBriefView, PlanReviewView and ExecutionView
are different presentations of one shared workflow rather than independent
features with separate data lifecycles.

The state flow is:

SwiftUI user intent
→ BirthdayAgent
→ BirthdayPlanning and PartyTool
→ published agent state, tasks and logs
→ SwiftUI rendering

Separate screen ViewModels would currently add forwarding layers and risk
duplicated state without creating a meaningful responsibility boundary.

A separate presentation ViewModel may be introduced when presentation
transformation, navigation coordination or independent asynchronous work
becomes substantial.

## Lightweight native SwiftUI design system

BirthdayPartyPilot uses a small internal design system instead of a third-party
UI framework.

This keeps the app visually consistent while preserving native SwiftUI
behavior, accessibility, Dynamic Type and dark-mode support.

The design system is intentionally limited to shared tokens and repeated
presentation components. It does not own workflow state or business logic.