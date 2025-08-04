# Candidate Coding Exercises for the *Simple Certs* App

Below are several proposed exercises related to the **Simple Certs** renewable energy certificate registry. Each exercise focuses on different aspects of the system (business logic, API design, data integrity, background processing) to evaluate a candidate’s problem‑solving approach and prioritization. Candidates should **choose one exercise** and spend roughly **1‑2 hours** implementing a solution.

*Instructions for Candidates:* For the exercise you choose, be prepared to discuss your design decisions, any assumptions you made, and how you prioritized the work. You may use any tools or resources (including frameworks or AI assistants) during implementation. Focus on writing clear, well‑structured code and consider edge cases or future implications of your design.

---

## Exercise 1 — Transaction Log & Concurrency Control

**Scenario**  
The integrity of the system is paramount—like a banking system, we need a reliable audit trail of all actions *and* a guarantee that concurrent operations don’t corrupt data. Currently the app records no comprehensive history and has no safeguards against race conditions.

**Your Task**

1. **Transaction log**
    * Create an append‑only `Transaction` (or similarly named) table that records every state‑changing event (certificate issuance, split, transfer, retirement, etc.).
    * Log enough data to reconstruct state (event type, related IDs, timestamps, quantities, before/after values, etc.).
    * Ensure “all‑or‑nothing”: a failed operation must not leave a partial log entry; a successful one must always log.

2. **Sequential processing / concurrency protection**  
   Choose a strategy to ensure only one state‑changing operation for the same record(s) runs at a time:
    * **DB locking**—wrap each business action in a transaction that obtains row or advisory locks, *or*
    * **Job queue**—enqueue every action into a single queue processed serially.  
      Handle race cases such as two users attempting to split or transfer the same certificate simultaneously.

**Deliverables**  
Schema/migration, model code, and updated service/controller logic that:

* Writes the log entries.
* Prevents data races.
* Includes a brief note on how state could be replayed from the log.

---

## Exercise 2 — Enforce Data‑Integrity Invariants

**Scenario**  
Certain domain rules must *always* hold true, but the current code doesn’t enforce them.

**Invariants to enforce (at minimum)**

* **Contiguous generation dates** per `Generator` (no gaps or overlaps).
* **Unique certificates** for a generation event (no duplicates).
* **Certificate quantity conservation**—sum of all pieces derived from a certificate must equal the original quantity; no zero or negative pieces.
* *(Optional bonus)* **Balanced accounts**—cannot retire more energy than produced.

**Your Task**

* Add model validations, DB constraints, or service‑layer guards that prevent API calls from breaking these rules.
* Return clear HTTP 422 errors detailing which rule was violated.

**Deliverables**  
Updated models/migrations/tests plus a short list of the invariants you implemented and how.

---

## Exercise 3 — Support Multi‑Fuel Generators (Design Extension)

**Scenario**  
A single generating station can be a hybrid (e.g., wind + solar). The current schema assumes one fuel per `Generator`.

**Your Task**

* Extend the data model so a generator can have multiple fuel types. Options:
    * Introduce a `FuelType` join table.
    * Treat a hybrid as multiple sub‑generators.
* Define how `Generation` records capture each fuel’s MWh (separate rows vs. new columns).
* Adjust certificate issuance so each fuel’s energy results in distinguishable certificates.
* Ensure energy accounting still balances.

**Deliverables**  
Migrations, model changes, and example code or tests showing a hybrid generator issuing correct certificates, with an explanation of design choices and trade‑offs.

---

## Exercise 4 — Background Job: Expire Stale Transfers

**Scenario**  
A `CertificateQuantity` moved to `"intransit"` waits on the recipient’s acceptance. It can currently linger forever.

**Your Task**

1. Define a “stale” threshold (e.g., > 24 h in `intransit`).
2. Implement `CancelStaleTransfersJob` (ActiveJob or Sidekiq) to:
    * Find qualifying records.
    * Revert them to `"active"` and clear `to_organization`.
    * Log the auto‑cancellation (tie into Exercise 1 if implemented).
3. Show how you would schedule the job (cron, `sidekiq‑cron`, or Rake task).

**Deliverables**  
Job code plus a way to demonstrate it (manual invoke or test). Document config/assumptions such as the timeout length.

---

### What We’re Looking For

* Clear, maintainable code and reasonable test coverage.
* Thoughtful trade‑offs: correctness vs speed, completeness vs scope.
* Ability to communicate assumptions and next steps.

Pick any **one** exercise and spend no more than **1–2 hours** on it. We’ll discuss your approach in the follow‑up conversation. Good luck!
