import type { ClusterAggregationResponse } from "../../application/dtos/ClusterAggregationDto";
import type { ClusterAggregationOutputPort } from "../../application/ports/output/ClusterAggregationOutputPort";
import type { StatisticalSummary } from "../../domain/services/StatisticalAnalysisService";

export class ClusterAggregationPresenter
	implements ClusterAggregationOutputPort
{
	presentSuccess(
		processedCount: number,
		summary?: StatisticalSummary,
	): ClusterAggregationResponse {
		const response: ClusterAggregationResponse = {
			status: "ok",
			processedCount,
		};

		if (summary) {
			response.statistics = {
				totalUsers: summary.totalUsers,
				totalAnswers: summary.totalAnswers,
				questionsAnalyzed: summary.questionsAnalyzed,
				clusterCount: summary.clusterCount,
				silhouetteScore: summary.silhouetteScore,
				inertia: summary.inertia,
			};
		}

		return response;
	}

	presentError(message: string): ClusterAggregationResponse {
		return {
			status: "error",
			message,
		};
	}
}
