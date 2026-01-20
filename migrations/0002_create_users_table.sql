-- ==============================
-- ユーザマスタ
-- ==============================
CREATE TABLE m_users (
    user_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    user_name   TEXT NOT NULL UNIQUE,
    created_at  INTEGER NOT NULL,
    updated_at  INTEGER NOT NULL
);

-- ==============================
-- 質問マスタ
-- ==============================
CREATE TABLE m_questions (
    question_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    question_text TEXT NOT NULL UNIQUE,
    created_at    INTEGER NOT NULL,
    updated_at    INTEGER NOT NULL
);

-- ==============================
-- 選択肢マスタ
-- ==============================
CREATE TABLE m_choices (
    choice_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id  INTEGER NOT NULL REFERENCES m_questions(question_id),
    choice_text  TEXT NOT NULL,
    choice_value INTEGER NOT NULL,
    created_at   INTEGER NOT NULL,
    updated_at   INTEGER NOT NULL,
    UNIQUE(question_id, choice_value),
    UNIQUE(question_id, choice_text)
);

-- ==============================
-- 日付マスタ
-- ==============================
CREATE TABLE m_survey_dates (
    date_id     INTEGER PRIMARY KEY,  -- YYYYMMDD 形式
    date_text   TEXT NOT NULL,        -- 'YYYY-MM-DD'
    weekday     INTEGER NOT NULL,     -- 0=日曜～6=土曜
    is_holiday  INTEGER DEFAULT 0,    -- 0=平日, 1=休日
    created_at  INTEGER NOT NULL,
    updated_at  INTEGER NOT NULL
);

-- ==============================
-- バッチマスタ
-- ==============================
CREATE TABLE m_batch (
    batch_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    batch_type    TEXT NOT NULL,      -- 'answers', 'clusters' など
    executed_at   INTEGER NOT NULL,   -- UNIXタイムスタンプ
    finished_at   INTEGER,            -- 終了時刻
    processed_rows INTEGER DEFAULT 0, -- 処理件数
    status        TEXT NOT NULL,      -- 'pending', 'done', 'failed'
    created_at    INTEGER NOT NULL,
    updated_at    INTEGER NOT NULL
);

-- ==============================
-- 回答結果（未集計）
-- ==============================
CREATE TABLE raw_answers (
    answer_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id      INTEGER NOT NULL REFERENCES m_users(user_id),
    question_id  INTEGER NOT NULL REFERENCES m_questions(question_id),
    choice_id    INTEGER NOT NULL REFERENCES m_choices(choice_id),
    date_id      INTEGER NOT NULL REFERENCES m_survey_dates(date_id),
    created_at   INTEGER NOT NULL,
    UNIQUE(user_id, question_id, date_id)  -- 同じ日の同じ質問に対して重複回答防止
);

-- ==============================
-- 回答結果（集計済み）
-- ==============================
CREATE TABLE processed_answers (
    processed_answer_id INTEGER PRIMARY KEY AUTOINCREMENT,
    batch_id     INTEGER NOT NULL REFERENCES m_batch(batch_id),
    user_id      INTEGER NOT NULL REFERENCES m_users(user_id),
    question_id  INTEGER NOT NULL REFERENCES m_questions(question_id),
    choice_id    INTEGER NOT NULL REFERENCES m_choices(choice_id),
    date_id      INTEGER NOT NULL REFERENCES m_survey_dates(date_id),
    created_at   INTEGER NOT NULL,
    UNIQUE(batch_id, user_id, question_id, date_id)
);

-- ==============================
-- クラスタ結果（集計済み）
-- ==============================
CREATE TABLE user_clusters (
    cluster_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    batch_id    INTEGER NOT NULL REFERENCES m_batch(batch_id),
    user_id     INTEGER NOT NULL REFERENCES m_users(user_id),
    cluster_no  INTEGER NOT NULL,
    created_at  INTEGER NOT NULL,
    UNIQUE(batch_id, user_id)
);

-- ==============================
-- クラスタ履歴
-- ==============================
CREATE TABLE cluster_history (
    history_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    batch_id    INTEGER NOT NULL REFERENCES m_batch(batch_id),
    user_id     INTEGER NOT NULL REFERENCES m_users(user_id),
    cluster_no  INTEGER NOT NULL,
    created_at  INTEGER NOT NULL
);

DROP TABLE IF EXISTS comments;
