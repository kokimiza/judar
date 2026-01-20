export interface QuestionCreationRequest {
	questionText: string;
	choices: Array<{
		text: string;
		value: number;
	}>;
}

export interface QuestionCreationResponse {
	status: "ok" | "error";
	questionId?: number;
	questionText?: string;
	choices?: Array<{
		id: number;
		text: string;
		value: number;
	}>;
	message?: string;
}
