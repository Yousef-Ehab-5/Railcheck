# Device acceptance checklist

These are manual checks, not claims of completed device tests.

- [ ] Add Train 205 / Carriage 3 / Doors / High with a description of at least 10 characters.
- [ ] Confirm a blank or whitespace-only field cannot save; train names may include letters.
- [ ] Rapidly tap Save. Exactly one report should appear.
- [ ] Close and reopen the app; report persists. Web: reopen the SAME browser and http://localhost:7357.
- [ ] Search train and description, combine filters. Counters still describe all saved reports.
- [ ] Edit text, save, and reopen. Created time stays fixed; updated time changes.
- [ ] Open can become In progress only; save. Reopen it, resolve with valid notes, and save.
- [ ] Reopen a Resolved report. Cancel once, then confirm; save and check resolution notes/time clear.
- [ ] Capture location with approximate permission. Check coordinates and capture time.
- [ ] Deny permission; form remains intact. Retry or Continue without location.
- [ ] Permanently deny permission; use App settings, return and retry.
- [ ] Disable system location; use Location settings, return and retry.
- [ ] No GPS fix / timeout: preserve typed fields and offer Retry / Continue without location.
- [ ] Request location then immediately uncheck it. Late results must not reattach location.
- [ ] Request location then discard/navigate away. No late setState or saved coordinates.
- [ ] Edit a report containing coordinates: text changes leave the old location untouched.
- [ ] Replace location, deny or time out; existing coordinates remain until explicitly removed.
- [ ] Delete one: Cancel preserves it; Confirm deletes it.
- [ ] Shake phone repeatedly on dashboard: only one delete-all confirmation dialog.
- [ ] Shake on the edit screen or while app is backgrounded: no delete-all dialog.
- [ ] Delete all includes filtered-out reports, and the dashboard becomes empty immediately.
- [ ] No reports / search with no matches show different useful empty states.
- [ ] Edit, then use app Back and system Back. Cancel preserves form; Discard leaves.
- [ ] At 320–360 px width and large text, scroll to every input and action with keyboard open.
- [ ] Enter long description and resolution notes. No clipping in detail view.
- [ ] Cause a storage error (e.g. browser denies storage). Retry must not erase typed input or database.
- [ ] Web: verify browser refresh persistence; do not use Incognito for durable records.
- [ ] iPhone: foreground location and physical shake work after configuring signing on a Mac.

Emulator notes: Set a location in Extended Controls > Location. Physical shaking is
best verified on a real phone; the dashboard delete-all toolbar button exercises
exactly the same confirmation/delete flow on Web and emulators.
