# Survey Response System

アンケート回答システム - Cloudflare Workers + D1 Database を使用したクリーンアーキテクチャ実装

## 概要

このシステムは、JWT認証付きのアンケート回答収集・集計・クラスタリングを行うWebAPIです。クリーンアーキテクチャの原則に従って設計されており、依存関係が内側に向くように構成されています。

## 機能

### 1. ユーザー登録 (`POST /signup`)
- ユーザー名、メールアドレス、パスワードの登録
- 重複チェック機能
- パスワードハッシュ化
- バリデーション機能

### 2. ログイン (`POST /login`)
- メールアドレス・パスワード認証
- JWTトークン発行
- 認証情報の検証

### 3. 質問作成 (`POST /questions`) ※認証必要
- 質問と選択肢の作成
- バリデーション機能

### 4. アンケート回答投稿 (`POST /submit`) ※認証必要
- 複数質問への回答を一括投稿
- 認証されたユーザーのみ投稿可能
- 重複回答チェック
- データバリデーション

### 5. 日次集計・クラスタリング (scheduled)
- 未集計データの自動処理
- ユーザーのクラスタリング
- バッチ処理による効率的な集計

## セキュリティ

- **JWT認証**: Bearer Token方式
- **パスワードハッシュ化**: SHA-256 + ソルト
- **CORS対応**: クロスオリジンリクエスト対応
- **認証コンテキスト**: リクエストレベルでの認証状態管理

## データベーススキーマ

### マスターテーブル
- `m_users`: ユーザーマスター（認証情報含む）
- `m_questions`: 質問マスター
- `m_choices`: 選択肢マスター
- `m_survey_dates`: 日付マスター
- `m_batch`: バッチマスター

### データテーブル
- `raw_answers`: 未集計回答データ
- `processed_answers`: 集計済み回答データ
- `user_clusters`: ユーザークラスター結果
- `cluster_history`: クラスター履歴

## セットアップ

### 1. 依存関係のインストール
```bash
npm install
```

### 2. データベースマイグレーション
```bash
# ローカル環境
npx wrangler d1 execute d1-judar-database --file=migrations/0001_create_comments_table.sql
npx wrangler d1 execute d1-judar-database --file=migrations/0002_create_users_table.sql
npx wrangler d1 execute d1-judar-database --file=migrations/0003_add_user_auth.sql

# 本番環境
npx wrangler d1 execute d1-judar-database --file=migrations/0001_create_comments_table.sql --remote
npx wrangler d1 execute d1-judar-database --file=migrations/0002_create_users_table.sql --remote
npx wrangler d1 execute d1-judar-database --file=migrations/0003_add_user_auth.sql --remote
```

### 3. 環境変数設定
```bash
# 本番環境でJWT秘密鍵を設定
wrangler secret put JWT_SECRET
```

### 4. 開発サーバー起動
```bash
# 開発用設定ファイルを使用
wrangler dev --config wrangler.dev.json
```

## API仕様

### 認証不要エンドポイント

#### ユーザー登録

**POST** `/signup`

**リクエスト:**
```json
{
  "userName": "testuser",
  "email": "test@example.com",
  "password": "securepassword123"
}
```

**レスポンス（成功）:**
```json
{
  "status": "ok",
  "userId": 1,
  "userName": "testuser",
  "email": "test@example.com"
}
```

**レスポンス（エラー）:**
```json
{
  "status": "error",
  "message": "Email already exists"
}
```

#### ログイン

**POST** `/login`

**リクエスト:**
```json
{
  "email": "test@example.com",
  "password": "securepassword123"
}
```

**レスポンス（成功）:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "userId": 1,
    "userName": "testuser",
    "email": "test@example.com"
  }
}
```

**レスポンス（エラー）:**
```json
{
  "success": false,
  "error": "Invalid email or password"
}
```

### 認証必要エンドポイント

**認証ヘッダー:**
```
Authorization: Bearer <JWT_TOKEN>
```

#### 質問作成

**POST** `/questions`

**リクエスト:**
```json
{
  "questionText": "あなたの好きな色は何ですか？",
  "choices": [
    {"text": "赤", "value": 1},
    {"text": "青", "value": 2},
    {"text": "緑", "value": 3},
    {"text": "黄", "value": 4}
  ]
}
```

**レスポンス（成功）:**
```json
{
  "status": "ok",
  "questionId": 1,
  "questionText": "あなたの好きな色は何ですか？",
  "choices": [
    {"id": 1, "text": "赤", "value": 1},
    {"id": 2, "text": "青", "value": 2},
    {"id": 3, "text": "緑", "value": 3},
    {"id": 4, "text": "黄", "value": 4}
  ]
}
```

**レスポンス（エラー）:**
```json
{
  "status": "error",
  "message": "Question already exists"
}
```

#### アンケート回答投稿

**POST** `/submit`

**リクエスト:**
```json
{
  "userId": 1,
  "answers": [
    {"questionId": 1, "choiceId": 2},
    {"questionId": 2, "choiceId": 1},
    {"questionId": 3, "choiceId": 3}
  ]
}
```

**レスポンス（成功）:**
```json
{
  "status": "ok"
}
```

**レスポンス（エラー）:**
```json
{
  "status": "error",
  "message": "Unauthorized access"
}
```

## 使用例

### 1. ユーザー登録
```bash
curl -X POST https://your-worker.your-subdomain.workers.dev/signup \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "testuser",
    "email": "test@example.com",
    "password": "securepassword123"
  }'
```

### 2. ログイン
```bash
curl -X POST https://your-worker.your-subdomain.workers.dev/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "securepassword123"
  }'
```

### 3. 質問作成（認証必要）
```bash
curl -X POST https://your-worker.your-subdomain.workers.dev/questions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -d '{
    "questionText": "あなたの好きな色は何ですか？",
    "choices": [
      {"text": "赤", "value": 1},
      {"text": "青", "value": 2},
      {"text": "緑", "value": 3},
      {"text": "黄", "value": 4}
    ]
  }'
```

### 4. アンケート回答投稿（認証必要）
```bash
curl -X POST https://your-worker.your-subdomain.workers.dev/submit \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -d '{
    "userId": 1,
    "answers": [
      {"questionId": 1, "choiceId": 2},
      {"questionId": 2, "choiceId": 1},
      {"questionId": 3, "choiceId": 3}
    ]
  }'
```

## 技術スタック

- **Runtime**: Cloudflare Workers
- **Database**: Cloudflare D1 (SQLite)
- **Language**: TypeScript
- **Architecture**: Clean Architecture
- **Authentication**: JWT (HS256)
- **Password Hashing**: SHA-256 + Salt
- **Build Tool**: Wrangler

## セキュリティ考慮事項

1. **JWT秘密鍵管理**: 本番環境では強力なランダム文字列を使用
2. **HTTPS必須**: 本番環境では必ずHTTPS経由でアクセス
3. **パスワード管理**: ハッシュ化されたパスワードのみ保存
4. **認証コンテキスト**: リクエストレベルでの適切な認証状態管理
5. **CORS設定**: 適切なクロスオリジン設定
