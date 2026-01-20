export class Cluster {
	constructor(
		public readonly id: number,
		public readonly batchId: number,
		public readonly userId: number,
		public readonly clusterNo: number,
		public readonly createdAt: Date,
	) {}

	static create(
		batchId: number,
		userId: number,
		clusterNo: number,
	): Omit<Cluster, "id" | "createdAt"> {
		return { batchId, userId, clusterNo };
	}
}
