import type { Batch, BatchType } from "../entities/Batch";

export interface BatchRepository {
	/**
	 * 新しいバッチを開始する（pending状態で作成）
	 */
	startBatch(batchType: BatchType): Promise<number>;

	/**
	 * バッチを完了状態に更新する
	 */
	completeBatch(batchId: number, processedRows: number): Promise<void>;

	/**
	 * バッチを失敗状態に更新する
	 */
	failBatch(batchId: number): Promise<void>;

	/**
	 * バッチ情報を取得する
	 */
	getBatch(batchId: number): Promise<Batch | null>;

	/**
	 * バッチ履歴を取得する
	 */
	getBatchHistory(limit?: number): Promise<Batch[]>;
}
