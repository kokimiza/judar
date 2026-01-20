-- ==============================
-- ユーザー認証情報追加
-- ==============================

-- Step 1: カラムを追加（UNIQUE制約なし）
ALTER TABLE m_users ADD COLUMN password_hash TEXT;
ALTER TABLE m_users ADD COLUMN salt TEXT;
ALTER TABLE m_users ADD COLUMN email TEXT;

-- Step 2: emailカラムにUNIQUE制約を追加
CREATE UNIQUE INDEX idx_users_email ON m_users(email) WHERE email IS NOT NULL;