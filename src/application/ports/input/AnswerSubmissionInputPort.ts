import type {
	AnswerSubmissionRequest,
	AnswerSubmissionResponse,
} from "../../dtos/AnswerSubmissionDto";

export interface AnswerSubmissionInputPort {
	submit(request: AnswerSubmissionRequest): Promise<AnswerSubmissionResponse>;
}
