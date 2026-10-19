<!-- astrocode builtin command (ported from oh-my-openagent) -->
# Hyperplan (astrocode fallback)

Team-mode is not available in astrocode, so run a single-agent adversarial planning pass instead:

1. Restate the planning request and the concrete end state.
2. Enumerate the strongest objections to the obvious approach (constraints, failure modes,
   blast radius, reversibility, cost).
3. Produce 2-3 competing plans, each with trade-offs.
4. Consult `oracle` (read-only, expensive) for the hardest architectural risks.
5. Have `prometheus` write the chosen plan to `.sisyphus/plans/`.
6. Summarize the decision, rejected alternatives, and open risks.

<user-request>
$ARGUMENTS
</user-request>
