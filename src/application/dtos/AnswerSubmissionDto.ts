export interface AnswerSubmissionRequest {
	userId: number;
	answers: Array<{
		questionId: number;
		choiceId: number;
	}>;
}

export interface AnswerSubmissionResponse {
	status: "ok" | "error";
	message?: string;
}
