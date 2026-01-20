import type {
	QuestionCreationRequest,
	QuestionCreationResponse,
} from "../../dtos/QuestionCreationDto";

export interface QuestionCreationInputPort {
	createQuestion(
		request: QuestionCreationRequest,
	): Promise<QuestionCreationResponse>;
}
