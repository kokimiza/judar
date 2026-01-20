export type ClusterAggregationRequest = {};

export interface ClusterAggregationResponse {
	status: "ok" | "error";
	processedCount?: number;
	message?: string;
	statistics?: {
		totalUsers: number;
		totalAnswers: number;
		questionsAnalyzed: number;
		clusterCount: number;
		silhouetteScore?: number;
		inertia?: number; // クラスター内分散の合計
	};
}
