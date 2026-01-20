# Survey Response System

アンケート回答システム - Cloudflare Workers + D1 Database を使用したクリーンアーキテクチャ実装

## 概要

このシステムは、アンケート回答の収集・集計・クラスタリングを行うWebAPIです。クリーンアーキテクチャの原則に従って設計されており、依存関係が内側に向くように構成されています。

## アーキテクチャ

### 層構造

```
src/
├── domain/                    # ドメイン層
│   ├── entities/             # エンティティ
│   │   ├── User.ts
│   │   ├── Answer.ts
│   │   └── Cluster.ts
│   ├── values/               # 値オブジェクト
│   │   └── DateId.ts
│   ├── services/             # ドメインサービス
│   │   ├── UserDomainService.ts
│   │   └── AnswerDomainService.ts
│   └── repositories/         # リポジトリインターフェース
│       ├── UserRepository.ts
│       ├── AnswerRepository.ts
│       └── ClusterRepository.ts
├── application/              # アプリケーション層
│   ├── dtos/                # データ転送オブジェクト
│   │   ├── UserRegistrationDto.ts
│   │   ├── AnswerSubmissionDto.ts
│   │   └── ClusterAggregationDto.ts
│   ├── ports/               # ポート（インターフェース）
│   │   ├── input/           # Input Port
│   │   │   ├── UserRegistrationInputPort.ts
│   │   │   ├── AnswerSubmissionInputPort.ts
│   │   │   └── ClusterAggregationInputPort.ts
│   │   └── output/          # Output Port
│   │       ├── UserRegistrationOutputPort.ts
│   │       ├── AnswerSubmissionOutputPort.ts
│   │       └── ClusterAggregationOutputPort.ts
│   └── interactors/         # インタラクター（ユースケース実装）
│       ├── UserRegistrationInteractor.ts
│       ├── AnswerSubmissionInteractor.ts
│       └── ClusterAggregationInteractor.ts
├── infrastructure/          # インフラ層
│   └── repositories/        # リポジトリ実装
│       ├── D1UserRepository.ts
│       ├── D1AnswerRepository.ts
│       └── D1ClusterRepository.ts
├── adapters/               # アダプター層
│   ├── controllers/        # コントローラー
│   │   ├── UserRegistrationController.ts
│   │   ├── AnswerSubmissionController.ts
│   │   └── ClusterAggregationController.ts
│   └── presenters/         # プレゼンター
│       ├── UserRegistrationPresenter.ts
│       ├── AnswerSubmissionPresenter.ts
│       └── ClusterAggregationPresenter.ts
└── index.ts               # DIコンテナ・エントリーポイント
```

### 依存関係の向き

```
外側 → 内側
Adapters → Application → Domain
Infrastructure → Domain
```

- **ドメイン層**: ビジネスロジックの中核。他の層に依存しない
- **アプリケーション層**: ユースケースを実装。ドメイン層のみに依存
- **インフラ層**: 外部システム（DB等）との接続。ドメイン層のインターフェースを実装
- **アダプター層**: 外部からの入力とレスポンス処理

## 機能

### 1. ユーザー登録 (`/signup`)
- ユーザー名の登録
- 重複チェック機能
- バリデーション機能

### 2. アンケート回答投稿 (`/submit`)
- 複数質問への回答を一括投稿
- 重複回答チェック
- データバリデーション

### 3. 日次集計・クラスタリング (scheduled)
- 未集計データの自動処理
- ユーザーのクラスタリング
- バッチ処理による効率的な集計

## データベーススキーマ

### マスターテーブル
- `m_users`: ユーザーマスター
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
npx wrangler d1 migrations apply --local
```

### 3. 開発サーバー起動
```bash
npm run dev
```

サーバーは `http://localhost:8787` で起動します。

## API仕様

### ユーザー登録

**POST** `/signup`

```json
{
  "userName": "田中太郎"
}
```

**レスポンス（成功）:**
```json
{
  "status": "ok",
  "userId": 1,
  "userName": "田中太郎"
}
```

**レスポンス（エラー）:**
```json
{
  "status": "error",
  "message": "User name already exists"
}
```

### アンケート回答投稿

**POST** `/submit`

```json
{
  "user_id": 1,
  "answers": [
    {"question_id": 1, "choice_id": 2},
    {"question_id": 2, "choice_id": 1},
    {"question_id": 3, "choice_id": 3}
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
  "message": "Duplicate answers for the same question are not allowed"
}
```

## 使用例

### 1. ユーザー登録
```bash
curl -X POST http://localhost:8787/signup \
  -H "Content-Type: application/json" \
  -d '{"userName": "田中太郎"}'
```

### 2. アンケート回答投稿
```bash
curl -X POST http://localhost:8787/submit \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "answers": [
      {"question_id": 1, "choice_id": 2},
      {"question_id": 2, "choice_id": 1},
      {"question_id": 3, "choice_id": 3}
    ]
  }'
```

### 3. 複数ユーザーでのテスト
```bash
# ユーザー2を登録
curl -X POST http://localhost:8787/signup \
  -H "Content-Type: application/json" \
  -d '{"userName": "佐藤花子"}'

# ユーザー2の回答投稿
curl -X POST http://localhost:8787/submit \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 2,
    "answers": [
      {"question_id": 1, "choice_id": 1},
      {"question_id": 2, "choice_id": 3},
      {"question_id": 3, "choice_id": 2}
    ]
  }'
```

## バリデーション機能

### ユーザー登録時
- ユーザー名の空文字チェック
- ユーザー名の長さチェック（100文字以内）
- ユーザー名の重複チェック

### 回答投稿時
- 回答データの存在チェック
- 同一質問への重複回答チェック
- 質問ID・選択肢IDの妥当性チェック

## 技術スタック

- **Runtime**: Cloudflare Workers
- **Database**: Cloudflare D1 (SQLite)
- **Language**: TypeScript
- **Architecture**: Clean Architecture
- **Build Tool**: Wrangler

## 開発・デプロイ

### ローカル開発
```bash
npm run dev
```

### デプロイ
```bash
npm run deploy
```

### マイグレーション（本番）
```bash
npx wrangler d1 migrations apply --remote
```

## 設計思想

このシステムは以下の原則に従って設計されています：

1. **依存関係逆転の原則**: 高レベルモジュールが低レベルモジュールに依存しない
2. **単一責任の原則**: 各クラスは単一の責任を持つ
3. **開放閉鎖の原則**: 拡張に対して開いており、修正に対して閉じている
4. **インターフェース分離の原則**: クライアントが使用しないメソッドに依存しない
5. **依存関係注入**: 依存関係は外部から注入される

これにより、テスタブルで保守性の高いコードベースを実現しています。

