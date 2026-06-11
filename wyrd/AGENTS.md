<!-- BEGIN @agent-native/skills -->
## Efficient Frontier

When running any high-cost frontier model on a codebase-heavy task, act as the orchestrator and reviewer. Split independent research, search, summarization, coding, and testing work into cheaper/faster subagents when the host supports them, then spend frontier-model tokens on the plan, tradeoffs, integration decisions, validation strategy, and final quality pass. Delegated prompts should be self-contained: objective, repo path, scope, out-of-scope areas, expected evidence, verification commands, and stop conditions. For testing-heavy work, the frontier model should choose the scripts or browser flows that matter while lighter agents run checks, reduce output, and return the concrete signal. Treat delegated findings as leads and verify important claims before presenting them as facts.
<!-- END @agent-native/skills -->
