# Review: "Add cases and payoff calculation"

**Reviewed by Elian Canul. Two problems found, both fixed, both now covered by tests.**

This is a made-up example, not your system. I wrote a small change the way an AI assistant typically would, with two mistakes AI assistants commonly make, then reviewed it the way I would review a real pull request for you. I learned Supabase to build it.

## What the change did

It added a table of cases and a calculation for how much a client owes at payoff. It came with its own tests, and they passed. ([PR #1](../../pull/1))

## Problem 1: every employee could see every case

**What was wrong.** The access rule only asked "is this person logged in?". It never asked who they were.

**What would have happened.** Any salesperson could open any other salesperson's cases. So could anyone with a login and no role at all.

**What I changed.** One rule per role, and nothing by default:

| Role | Can read |
| --- | --- |
| Admin | Every case |
| Sales | Only the cases assigned to them |
| Underwriting | Only cases still awaiting a decision |
| Servicing | Only funded and paid-off cases |
| Logged in, no role | Nothing |
| Not logged in | Nothing |

**How you know it works.** There is one test for each row of that table. Five of them failed before the fix; all pass now.

## Problem 2: the payoff could be off by one cent

**What was wrong.** The calculation used the kind of decimal number computers store only approximately. When a fee landed on exactly half a cent, it sometimes rounded up and sometimes down.

**What would have happened.** A $2,500.50 advance at 3% a month for 3 months has a fee of $225.045. The payoff should be **$2,725.55**. The code said **$2,725.54**. Run the same advance for 5 months and the half cent rounded up instead. One cent is small, but a payoff letter that disagrees with the contract is not.

**What I changed.** The calculation now works only in whole cents, with one written rule: *the fee is rounded once, at the end, to the nearest cent, and exactly half a cent rounds up.*

**How you know it works.** Five payoff tests with the arithmetic written out next to each. Three failed before the fix; all pass now.

## What I assumed

- **I don't know your fee model, so I used a simple example:** a flat monthly fee on the original advance. If yours compounds, or has minimums or caps, the tests change but the method doesn't.
- **I don't know your roles.** I used admin, sales, underwriting and servicing, with the simplest sensible rule for each.
- **Rounding direction is your decision, not mine.** Half-up is a placeholder; it should match what your contracts say. Changing it is a one-line edit.

## What I did not check

Only reading is covered. Nobody can create or edit a case through the app in this example, so those rules were out of scope.

## See it for yourself

- [PR #2](../../pull/2): the review tests failing against the original change (red ✗)
- [PR #3](../../pull/3): the fix, with the same tests passing (green ✓)
