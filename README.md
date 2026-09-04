# RaceDay – Database & API Planning Notes

## Files in this folder
- `ERD.png` – Entity Relationship Diagram (Section A)
- `API_Endpoint_Plan.md` – Full endpoint plan (Section B)
- `RaceDay_Schema.sql` – SQL Server schema + seed data (Section C)

## Design decisions

**Entities (6):** Users, Events, Categories, Routes, Enrolments, Results.

**Users** holds both Organisers and Participants in one table, distinguished
by the `Role` column (`Organiser`, `Participant`, `Admin`). This avoids
duplicating shared attributes (name, email, password) across two separate
tables and matches the role-based design required by the brief.

**Relationships and cardinality:**
- `Users` (1) — (M) `Events`: one Organiser can create many Events.
- `Events` (1) — (M) `Categories`: one Event can have many distance
  categories (e.g. 10km, 21km).
- `Categories` (1) — (1) `Routes`: each category has exactly one route.
- `Users` (M) — (M) `Categories`: a Participant can enter many categories,
  and a category can have many participants. This many-to-many relationship
  is resolved by the **`Enrolments`** junction table, which is why
  `Enrolments` has foreign keys to both `Users` and `Categories`.
- `Enrolments` (1) — (1) `Results`: each enrolment produces at most one
  result record.

**Why `Results` links to `Enrolments` rather than directly to `Users`/`Categories`:**
A result only makes sense in the context of a specific participant having
entered a specific category, which is exactly what an Enrolment record
represents. Linking Results to Enrolments avoids duplicating the
participant/category pair and keeps a single source of truth.

**Match between ERD and SQL script:**
The SQL script in `RaceDay_Schema.sql` creates tables in the same order and
with the same entities, primary keys, foreign keys, and cardinality shown in
`ERD.png`. No deliberate deviations were made.

**Seed data:** 2 Organisers, 2 Participants, 3 Events, 5 Categories (across
the 3 events), 5 Routes, 4 Enrolments, and 2 Results — meeting the minimum
data requirements in Section C.

## Successful CI
<img width="1344" height="655" alt="Screenshot 2026-09-04 211939" src="https://github.com/user-attachments/assets/5ddeb404-36f7-4425-90d9-6986af5f877c" />

## YouTube Link

https://youtu.be/0cAZ3wn4PnI
