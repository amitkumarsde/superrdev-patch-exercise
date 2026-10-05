# NOTES

## What I fixed

1. **Search showed wrong tasks**
   - Hidden (archived) tasks showed, and the status filter did not work.
   - Cause: no brackets in the SQL, so AND and OR mixed up.
   - Fix: added brackets in all 3 SQL places.

2. **Search was slow for no reason**
   - The code paused (`Thread.sleep`) up to 1 second.
   - Fix: removed the pause.

3. **Page stuck on "Loading..."**
   - On a server error, loading never stopped and the error was hidden.
   - Fix: always stop loading and show the error.

4. **Old results replaced new results**
   - When typing fast, an old answer could arrive last.
   - Fix: cancel old requests, and wait 300 ms after typing.

5. **Stuck on an empty page**
   - A new search stayed on the old page number.
   - Fix: go back to page 1 on a new search or filter.

6. **Server crashed on bad input**
   - A wrong status or page gave a 500 error.
   - Fix: check the input and return a clear 400 message.

7. **Small fixes**
   - `%` and `_` are searched as normal letters.
   - Stable page order (also sorted by `id`).
   - A logger instead of `System.out`, and no `console.log`.

## What I did not change

- **Paging in memory:** fine for 49 tasks. Changing it is a big job.
- **No tests added:** tested by hand to keep the change small.
- **H2 console and SQL logs:** useful for local work.

## Biggest risk left

- Every search loads **all matching tasks** into memory, so it will be slow with lots of data.
- **No tests**, so a future change can break search quietly.

## Tools and AI used

- **Claude (AI):** helped read the code, find bugs and write first drafts.
- **Me:** checked every bug, kept the fixes small, and tested in the browser and with API links.
