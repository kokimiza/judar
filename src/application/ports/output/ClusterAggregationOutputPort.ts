import type { StatisticalSummary } from "../../../domain/services/StatisticalAnalysisService";
import type { ClusterAggregationResponse } from "../../dtos/ClusterAggregationDto";

export interface ClusterAggregationOutputPort {
	presentSuccess(
		processedCount: number,
		summary?: StatisticalSummary,
	): ClusterAggregationResponse;
	presentError(message: string): ClusterAggregationResponse;
}
