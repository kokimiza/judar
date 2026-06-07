# judar CloudKit スキーマ定義

Container: `iCloud.productions.jocarium.judar`  
Database: `publicCloudDatabase`

---

## EnemyMaster

敵キャラのマスターデータ。開発者が一度だけ seed する。

| フィールド    | 型       | 説明                                       |
|--------------|----------|--------------------------------------------|
| name         | String   | 敵の名前（例：眠気の悪魔）                  |
| maxHP        | Int64    | 最大HP                                     |
| attackPower  | Int64    | 攻撃力                                     |
| asciiArt     | String   | 3行のアスキーアート                         |
| resistances  | [String] | 耐性属性のリスト（AttackType.rawValue）     |
| weaknesses   | [String] | 弱点属性のリスト（AttackType.rawValue）     |

RecordID: 自動生成（UUID）

---

## UserProfile

ユーザー1人につき1レコード。

| フィールド  | 型     | 説明                           |
|------------|--------|--------------------------------|
| userId     | String | Apple認証のユーザーID（主キー代わり） |
| familyId   | String | 所属するファミリーのID           |
| shareCode  | String | 他者が join するための6桁コード  |
| displayName| String | 表示名                          |

RecordID: `userId`（決定論的）

---

## FamilyEvent

育児ログ。家族全員の記録を同一 familyId で束ねる。

| フィールド    | 型     | 説明                                    |
|--------------|--------|-----------------------------------------|
| eventTypeRaw | String | "poop" / "pee" / "breastfeed" / "formula" |
| timestamp    | Date   | 記録日時                                 |
| familyId     | String | 所属ファミリーID（クエリ用）              |
| userId       | String | 記録者のユーザーID                       |

RecordID: 自動生成（UUID）  
インデックス: `familyId`, `timestamp`（NSPredicate クエリで使用）

---

## BattleProgress

家族単位のバトル進捗。アプリ再インストール後も途中から再開できる。

| フィールド    | 型     | 説明                                       |
|--------------|--------|--------------------------------------------|
| enemyName    | String | 現在交戦中の敵の名前（EnemyMaster.name）   |
| enemyCurrentHP | Int64 | 現在の敵HP（0以下 = 撃破済み）            |
| killStreak   | Int64  | 連続討伐数                                 |
| partyHP      | Int64  | パーティHP（上限 BattleState.initialPartyHP = 100） |
| familyId     | String | 所属ファミリーID                           |
| userId       | String | 最後に更新したユーザーID                   |

RecordID: `battleProgress_{familyId}`（決定論的 upsert）

---

## SwiftData モデル（ローカルキャッシュ）

### BabyEventRecord
FamilyEvent のローカル複製 + 同期状態フラグ。  
フィールド: `id`, `eventTypeRaw`, `timestamp`, `familyId`, `cloudKitRecordName`, `isSynced`, `syncErrorRaw`, `amount`

- `syncErrorRaw`: 最後のプッシュ失敗時のエラー文字列。成功時は空文字列にリセット。CloudKit 非対応（ローカル専用）
- `amount`: 粉ミルク量（ml）。0 = 未設定 / 該当なし。CloudKit 非対応（ローカル専用）

### CachedEnemyRecord
EnemyMaster のローカルキャッシュ。  
フィールド: `id`, `cloudKitRecordName`, `name`, `maxHP`, `resistancesJSON`, `weaknessesJSON`, `attackPower`, `asciiArt`, `lastSynced`

### LocalUserProfile
UserProfile のローカルキャッシュ。  
フィールド: `userId`, `appleUserId`, `familyId`, `shareCode`, `username`, `childBirthday`, `childGenderRaw`, `displayName`, `cloudKitRecordName`, `createdAt`

### CachedBattleProgress
BattleProgress のローカルキャッシュ（アプリ内1行のみ）。  
フィールド: `enemyName`, `enemyCurrentHP`, `killStreak`, `partyHP`, `updatedAt`

ストア: App Group `group.productions.jocarium.judar` / `judar.store`（アプリ＋ウィジェット共用）
