import type {
	ClusterAggregationRequest,
	ClusterAggregationResponse,
} from "../../dtos/ClusterAggregationDto";

export interface ClusterAggregationInputPort {
	aggregate(
		request: ClusterAggregationRequest,
	): Promise<ClusterAggregationResponse>;
}
