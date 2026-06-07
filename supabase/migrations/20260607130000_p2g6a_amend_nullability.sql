-- P2.G6a amendment: nullability relaxations.
-- Permits SQLite placeholders (SRC_PRISM_NO_PUBLIC_EVIDENCE_FOUND with source_class='none')
-- and contradictions with fewer than two related atoms to import.
-- Strictly additive — relaxes existing constraints, narrows nothing.

ALTER TABLE private.sources       ALTER COLUMN source_class DROP NOT NULL;
ALTER TABLE private.atoms          ALTER COLUMN source_class DROP NOT NULL;
ALTER TABLE private.contradictions ALTER COLUMN atom_a_id   DROP NOT NULL;
ALTER TABLE private.contradictions ALTER COLUMN atom_b_id   DROP NOT NULL;
