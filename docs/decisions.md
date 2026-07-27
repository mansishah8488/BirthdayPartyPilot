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