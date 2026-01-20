import type { QuestionCreationResponse } from "../../application/dtos/QuestionCreationDto";
import type { QuestionCreationOutputPort } from "../../application/ports/output/QuestionCreationOutputPort";
import type { QuestionWithChoices } from "../../domain/services/QuestionDomainService";

export class QuestionCreationPresenter implements QuestionCreationOutputPort {
	presentSuccess(
		questionWithChoices: QuestionWithChoices,
	): QuestionCreationResponse {
		return {
			status: "ok",
			questionId: questionWithChoices.question.id,
			questionText: questionWithChoices.question.text,
			choices: questionWithChoices.choices.map((choice) => ({
				id: choice.id,
				text: choice.text,
				value: choice.value,
			})),
		};
	}

	presentError(message: string): QuestionCreationResponse {
		return {
			status: "error",
			message,
		};
	}
}
