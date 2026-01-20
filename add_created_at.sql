ALTER TABLE artists ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE albums ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE songs ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();
