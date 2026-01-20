import type { ClusterAggregationRequest } from "../../application/dtos/ClusterAggregationDto";
import type { ClusterAggregationInputPort } from "../../application/ports/input/ClusterAggregationInputPort";

export class ClusterAggregationController {
	constructor(private readonly inputPort: ClusterAggregationInputPort) {}

	async handle(): Promise<void> {
		const dto: ClusterAggregationRequest = {};
		await this.inputPort.aggregate(dto);
	}
}
