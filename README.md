# RLS and money review example

A small, self-contained example of reviewing an AI-written database change in a Next.js + Supabase app: one access rule that leaks data and one fee calculation that loses a cent, each proven by a failing test and then fixed.

**Start with the report: [as a page](https://eliancanul.github.io/rls-and-money-review-example/)** or as [REVIEW.md](REVIEW.md). Two-minute read, no jargon.

The history is the example:

1. [PR #1](../../pull/1) is the "AI-written" change. Its own tests pass.
2. [PR #2](../../pull/2) adds review tests. They fail, on purpose.
3. [PR #3](../../pull/3) fixes both defects. The same tests pass.

Run it yourself (needs Docker and the [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started)):

```sh
supabase db start   # local Postgres with every migration applied
supabase test db    # runs supabase/tests/*.test.sql
```

Everything here is synthetic: the people, the cases, the four roles and the fee formula are made up for the example. The two defects in PR #1 were planted deliberately.
