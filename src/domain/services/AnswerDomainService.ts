import { Answer } from "../entities/Answer";
import { DateId } from "../values/DateId";

export class AnswerDomainService {
	validateAnswers(answers: Array<{ questionId: number; choiceId: number }>): {
		isValid: boolean;
		error?: string;
	} {
		if (!answers || answers.length === 0) {
			return { isValid: false, error: "At least one answer is required" };
		}

		// 同じ質問に対する重複回答をチェック
		const questionIds = answers.map((a) => a.questionId);
		const uniqueQuestionIds = new Set(questionIds);

		if (questionIds.length !== uniqueQuestionIds.size) {
			return {
				isValid: false,
				error: "Duplicate answers for the same question are not allowed",
			};
		}

		// 各回答の値をチェック
		for (const answer of answers) {
			if (!Number.isInteger(answer.questionId) || answer.questionId <= 0) {
				return { isValid: false, error: "Invalid question ID" };
			}

			if (!Number.isInteger(answer.choiceId) || answer.choiceId <= 0) {
				return { isValid: false, error: "Invalid choice ID" };
			}
		}

		return { isValid: true };
	}

	createAnswersForUser(
		userId: number,
		answers: Array<{ questionId: number; choiceId: number }>,
		dateId?: DateId,
	): Omit<Answer, "id" | "createdAt">[] {
		const targetDateId = dateId || DateId.today();

		return answers.map((answer) =>
			Answer.create(
				userId,
				answer.questionId,
				answer.choiceId,
				targetDateId.getValue(),
			),
		);
	}
}
