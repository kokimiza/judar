import {
	Batch,
	type BatchStatus,
	type BatchType,
} from "../../domain/entities/Batch";
import type { BatchRepository } from "../../domain/repositories/BatchRepository";

interface BatchRow {
	batch_id: number;
	batch_type: string;
	executed_at: number;
	finished_at: number | null;
	processed_rows: number;
	status: string;
	created_at: number;
	updated_at: number;
}

export class D1BatchRepository implements BatchRepository {
	constructor(private readonly db: D1Database) {}

	async startBatch(batchType: BatchType): Promise<number> {
		const now = Math.floor(Date.now() / 1000);

		const stmt = this.db.prepare(`
			INSERT INTO m_batch (batch_type, executed_at, finished_at, processed_rows, status, created_at, updated_at)
			VALUES (?, ?, NULL, 0, 'pending', ?, ?)
		`);

		const result = await stmt.bind(batchType, now, now, now).run();

		if (!result.meta.last_row_id) {
			throw new Error("Failed to create batch record");
		}

		return result.meta.last_row_id as number;
	}

	async completeBatch(batchId: number, processedRows: number): Promise<void> {
		const now = Math.floor(Date.now() / 1000);

		const stmt = this.db.prepare(`
			UPDATE m_batch 
			SET finished_at = ?, processed_rows = ?, status = 'done', updated_at = ?
			WHERE batch_id = ?
		`);

		await stmt.bind(now, processedRows, now, batchId).run();
	}

	async failBatch(batchId: number): Promise<void> {
		const now = Math.floor(Date.now() / 1000);

		const stmt = this.db.prepare(`
			UPDATE m_batch 
			SET finished_at = ?, status = 'failed', updated_at = ?
			WHERE batch_id = ?
		`);

		await stmt.bind(now, now, batchId).run();
	}

	async getBatch(batchId: number): Promise<Batch | null> {
		const stmt = this.db.prepare(`
			SELECT * FROM m_batch WHERE batch_id = ? LIMIT 1
		`);

		const result = await stmt.bind(batchId).first();

		if (!result) {
			return null;
		}

		return this.mapRowToBatch(result as unknown as BatchRow);
	}

	async getBatchHistory(limit = 50): Promise<Batch[]> {
		const stmt = this.db.prepare(`
			SELECT * FROM m_batch 
			ORDER BY created_at DESC 
			LIMIT ?
		`);

		const { results } = await stmt.bind(limit).all();

		return results.map((row) => this.mapRowToBatch(row as unknown as BatchRow));
	}

	private mapRowToBatch(row: BatchRow): Batch {
		return new Batch(
			row.batch_id,
			row.batch_type as BatchType,
			new Date(row.executed_at * 1000),
			row.finished_at ? new Date(row.finished_at * 1000) : null,
			row.processed_rows,
			row.status as BatchStatus,
			new Date(row.created_at * 1000),
			new Date(row.updated_at * 1000),
		);
	}
}
