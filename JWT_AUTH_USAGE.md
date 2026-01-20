# JWT認証 使用方法

## 概要

JWT + HTTPS認証を実装しました。これにより、iOSアプリから安全にAPIを利用できます。

## 環境設定

### 開発環境
```bash
npm run dev
```

## エンドポイント

### 認証不要
- `POST /signup` - ユーザー登録
- `POST /login` - ログイン

### 認証必要 (JWT Bearer Token)
- `POST /submit` - 回答送信
- `POST /questions` - 質問作成

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

レスポンス例:
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

### 3. 認証が必要なAPI呼び出し
```bash
curl -X POST https://your-worker.your-subdomain.workers.dev/submit \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "userId": 1,
    "questionId": 1,
    "choiceId": 1,
    "dateId": 20250120
  }'
```

## iOSアプリでの実装例

```swift
// ログイン
func login(email: String, password: String) async throws -> LoginResponse {
    let url = URL(string: "https://your-worker.your-subdomain.workers.dev/login")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["email": email, "password": password]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(LoginResponse.self, from: data)
}

// 認証付きAPI呼び出し
func submitAnswer(token: String, userId: Int, questionId: Int, choiceId: Int) async throws {
    let url = URL(string: "https://your-worker.your-subdomain.workers.dev/submit")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let body = [
        "userId": userId,
        "questionId": questionId,
        "choiceId": choiceId,
        "dateId": 20250120
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    
    let (_, _) = try await URLSession.shared.data(for: request)
}
```

## セキュリティ設定

### JWT設定
- トークン有効期限: 24時間
- アルゴリズム: HS256
- 自動更新: 必要に応じてリフレッシュトークンを実装

## マイグレーション実行

新しいマイグレーションを実行してください:
```bash
wrangler d1 execute d1-judar-database --file=migrations/0003_add_user_auth.sql
```

## 注意事項

1. **HTTPS必須**: 本番環境では必ずHTTPS経由でアクセス
2. **JWT_SECRET**: 本番では強力なランダム文字列を使用
3. **パスワード**: 最低8文字、複雑性要件を推奨
4. **トークン管理**: アプリ側でセキュアにトークンを保存
5. **秘密鍵管理**: 絶対にソースコードに秘密鍵を含めない