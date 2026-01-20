import type { ChoiceRepository } from "../../domain/repositories/ChoiceRepository";
import type { QuestionRepository } from "../../domain/repositories/QuestionRepository";
import { QuestionDomainService } from "../../domain/services/QuestionDomainService";
import type {
	QuestionCreationRequest,
	QuestionCreationResponse,
} from "../dtos/QuestionCreationDto";
import type { QuestionCreationInputPort } from "../ports/input/QuestionCreationInputPort";
import type { QuestionCreationOutputPort } from "../ports/output/QuestionCreationOutputPort";

export class QuestionCreationInteractor implements QuestionCreationInputPort {
	private readonly questionDomainService: QuestionDomainService;

	constructor(
		private readonly questionRepository: QuestionRepository,
		private readonly choiceRepository: ChoiceRepository,
		private readonly outputPort: QuestionCreationOutputPort,
	) {
		this.questionDomainService = new QuestionDomainService(
			questionRepository,
			choiceRepository,
		);
	}

	async createQuestion(
		request: QuestionCreationRequest,
	): Promise<QuestionCreationResponse> {
		try {
			// ドメインサービスで質問と選択肢をセットで作成
			const questionWithChoices =
				await this.questionDomainService.createQuestionWithChoices(
					request.questionText,
					request.choices,
				);

			return this.outputPort.presentSuccess(questionWithChoices);
		} catch (error) {
			const errorMessage =
				error instanceof Error ? error.message : "Question creation failed";
			return this.outputPort.presentError(errorMessage);
		}
	}
}
