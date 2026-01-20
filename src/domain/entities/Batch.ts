export type BatchStatus = "pending" | "done" | "failed";
export type BatchType = "cluster_aggregation";

export type BatchData = {
	batchType: BatchType;
	executedAt: Date;
	finishedAt: Date | null;
	processedRows: number;
	status: BatchStatus;
};

export class Batch {
	constructor(
		public readonly id: number,
		public readonly batchType: BatchType,
		public readonly executedAt: Date,
		public readonly finishedAt: Date | null,
		public readonly processedRows: number,
		public readonly status: BatchStatus,
		public readonly createdAt: Date,
		public readonly updatedAt: Date,
	) {}

	static create(batchType: BatchType): BatchData {
		const now = new Date();
		return {
			batchType,
			executedAt: now,
			finishedAt: null,
			processedRows: 0,
			status: "pending",
		};
	}

	markAsCompleted(processedRows: number): BatchData {
		return {
			batchType: this.batchType,
			executedAt: this.executedAt,
			finishedAt: new Date(),
			processedRows,
			status: "done",
		};
	}

	markAsFailed(): BatchData {
		return {
			batchType: this.batchType,
			executedAt: this.executedAt,
			finishedAt: new Date(),
			processedRows: this.processedRows,
			status: "failed",
		};
	}
}
