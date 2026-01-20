import type { AnswerRepository } from "../../domain/repositories/AnswerRepository";
import { AnswerDomainService } from "../../domain/services/AnswerDomainService";
import type {
	AnswerSubmissionRequest,
	AnswerSubmissionResponse,
} from "../dtos/AnswerSubmissionDto";
import type { AnswerSubmissionInputPort } from "../ports/input/AnswerSubmissionInputPort";
import type { AnswerSubmissionOutputPort } from "../ports/output/AnswerSubmissionOutputPort";
import type { AuthenticationContextService } from "../services/AuthenticationContextService";

export class AnswerSubmissionInteractor implements AnswerSubmissionInputPort {
	private readonly answerDomainService: AnswerDomainService;

	constructor(
		private readonly answerRepository: AnswerRepository,
		private readonly outputPort: AnswerSubmissionOutputPort,
		private readonly authContext: AuthenticationContextService,
	) {
		this.answerDomainService = new AnswerDomainService();
	}

	async submit(
		request: AnswerSubmissionRequest,
	): Promise<AnswerSubmissionResponse> {
		try {
			// 認証されたユーザーを取得
			const currentUser = this.authContext.getCurrentUser();
			if (!currentUser) {
				return this.outputPort.presentError("Authentication required");
			}

			// リクエストのuserIdと認証されたユーザーが一致するかチェック
			if (request.userId !== currentUser.userId) {
				return this.outputPort.presentError("Unauthorized access");
			}

			// ドメインサービスでバリデーション
			const validation = this.answerDomainService.validateAnswers(
				request.answers,
			);

			if (!validation.isValid) {
				return this.outputPort.presentError(
					validation.error || "Invalid answers",
				);
			}

			// ドメインサービスで回答エンティティを作成
			const answersToSave = this.answerDomainService.createAnswersForUser(
				currentUser.userId, // 認証されたユーザーIDを使用
				request.answers,
			);

			await this.answerRepository.saveAnswers(answersToSave);

			return this.outputPort.presentSuccess();
		} catch (error) {
			return this.outputPort.presentError("Answer submission failed");
		}
	}
}
