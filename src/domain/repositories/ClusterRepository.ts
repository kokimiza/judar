import type { Cluster } from "../entities/Cluster";

export interface ClusterRepository {
	saveClusters(clusters: Omit<Cluster, "id" | "createdAt">[]): Promise<void>;
}
