import type { AnswerSubmissionResponse } from "../../application/dtos/AnswerSubmissionDto";
import type { AnswerSubmissionOutputPort } from "../../application/ports/output/AnswerSubmissionOutputPort";

export class AnswerSubmissionPresenter implements AnswerSubmissionOutputPort {
	presentSuccess(): AnswerSubmissionResponse {
		return {
			status: "ok",
		};
	}

	presentError(message: string): AnswerSubmissionResponse {
		return {
			status: "error",
			message,
		};
	}
}
