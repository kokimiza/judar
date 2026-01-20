import type { QuestionWithChoices } from "../../../domain/services/QuestionDomainService";
import type { QuestionCreationResponse } from "../../dtos/QuestionCreationDto";

export interface QuestionCreationOutputPort {
	presentSuccess(
		questionWithChoices: QuestionWithChoices,
	): QuestionCreationResponse;
	presentError(message: string): QuestionCreationResponse;
}
