import type { AnswerSubmissionResponse } from "../../dtos/AnswerSubmissionDto";

export interface AnswerSubmissionOutputPort {
	presentSuccess(): AnswerSubmissionResponse;
	presentError(message: string): AnswerSubmissionResponse;
}
