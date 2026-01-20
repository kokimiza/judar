import type { Cluster } from "../../domain/entities/Cluster";
import type { ClusterRepository } from "../../domain/repositories/ClusterRepository";

export class D1ClusterRepository implements ClusterRepository {
	constructor(private readonly db: D1Database) {}

	async saveClusters(
		clusters: Omit<Cluster, "id" | "createdAt">[],
	): Promise<void> {
		if (clusters.length === 0) return;

		const stmt = this.db.prepare(
			`INSERT INTO user_clusters (batch_id, cluster_no, user_id, created_at)
       VALUES ${clusters.map(() => "(?, ?, ?, strftime('%s','now'))").join(", ")}`,
		);

		const bindValues: number[] = [];
		for (const cluster of clusters) {
			bindValues.push(cluster.batchId, cluster.clusterNo, cluster.userId);
		}

		await stmt.bind(...bindValues).run();
	}
}
