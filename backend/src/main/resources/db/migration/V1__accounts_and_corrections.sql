-- An account per Apple ID. apple_subject is Apple's stable, opaque user id:
-- no name, no email is stored.
CREATE TABLE accounts (
    id UUID PRIMARY KEY,
    apple_subject VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    -- Leera Plus until then; null for a free account.
    plus_until TIMESTAMP WITH TIME ZONE
);

-- One row per correction asked for, to count them against the quota. What
-- was written or said is never stored.
CREATE TABLE corrections (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX corrections_by_account ON corrections (account_id, created_at);
