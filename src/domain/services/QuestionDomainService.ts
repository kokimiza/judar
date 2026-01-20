import { Choice } from "../entities/Choice";
import { Question } from "../entities/Question";
import type { ChoiceRepository } from "../repositories/ChoiceRepository";
import type { QuestionRepository } from "../repositories/QuestionRepository";

export interface QuestionWithChoices {
	question: Question;
	choices: Choice[];
}

export class QuestionDomainService {
	constructor(
		private readonly questionRepository: QuestionRepository,
		private readonly choiceRepository: ChoiceRepository,
	) {}

	async validateQuestionText(
		text: string,
	): Promise<{ isValid: boolean; error?: string }> {
		if (!text || text.trim().length === 0) {
			return { isValid: false, error: "Question text cannot be empty" };
		}

		if (text.length > 500) {
			return {
				isValid: false,
				error: "Question text is too long (max 500 characters)",
			};
		}

		const existingQuestion = await this.questionRepository.findByText(text);
		if (existingQuestion) {
			return { isValid: false, error: "Question already exists" };
		}

		return { isValid: true };
	}

	validateChoices(choices: Array<{ text: string; value: number }>): {
		isValid: boolean;
		error?: string;
	} {
		if (!choices || choices.length === 0) {
			return { isValid: false, error: "At least one choice is required" };
		}

		if (choices.length > 10) {
			return { isValid: false, error: "Too many choices (max 10)" };
		}

		// 選択肢テキストの重複チェック
		const texts = choices.map((c) => c.text.trim());
		const uniqueTexts = new Set(texts);
		if (texts.length !== uniqueTexts.size) {
			return {
				isValid: false,
				error: "Duplicate choice texts are not allowed",
			};
		}

		// 選択肢値の重複チェック
		const values = choices.map((c) => c.value);
		const uniqueValues = new Set(values);
		if (values.length !== uniqueValues.size) {
			return {
				isValid: false,
				error: "Duplicate choice values are not allowed",
			};
		}

		// 各選択肢のバリデーション
		for (const choice of choices) {
			if (!choice.text || choice.text.trim().length === 0) {
				return { isValid: false, error: "Choice text cannot be empty" };
			}

			if (choice.text.length > 200) {
				return {
					isValid: false,
					error: "Choice text is too long (max 200 characters)",
				};
			}

			if (!Number.isInteger(choice.value) || choice.value <= 0) {
				return {
					isValid: false,
					error: "Choice value must be a positive integer",
				};
			}
		}

		return { isValid: true };
	}

	async createQuestionWithChoices(
		questionText: string,
		choices: Array<{ text: string; value: number }>,
	): Promise<QuestionWithChoices> {
		// 質問のバリデーション
		const questionValidation = await this.validateQuestionText(questionText);
		if (!questionValidation.isValid) {
			throw new Error(questionValidation.error);
		}

		// 選択肢のバリデーション
		const choicesValidation = this.validateChoices(choices);
		if (!choicesValidation.isValid) {
			throw new Error(choicesValidation.error);
		}

		// 質問を作成
		const questionToCreate = Question.create(questionText);
		const createdQuestion =
			await this.questionRepository.save(questionToCreate);

		// 選択肢を作成
		const choicesToCreate = choices.map((choice) =>
			Choice.create(createdQuestion.id, choice.text.trim(), choice.value),
		);

		const createdChoices =
			await this.choiceRepository.saveChoices(choicesToCreate);

		return {
			question: createdQuestion,
			choices: createdChoices,
		};
	}

	async validateQuestionAndChoicesExist(
		questionId: number,
		choiceIds: number[],
	): Promise<{ isValid: boolean; error?: string }> {
		try {
			// 質問に属する選択肢を取得
			const existingChoices =
				await this.choiceRepository.findByQuestionId(questionId);

			if (existingChoices.length === 0) {
				return {
					isValid: false,
					error: "Question not found or has no choices",
				};
			}

			// 指定された選択肢IDが質問に属するかチェック
			const existingChoiceIds = new Set(existingChoices.map((c) => c.id));
			const invalidChoiceIds = choiceIds.filter(
				(id) => !existingChoiceIds.has(id),
			);

			if (invalidChoiceIds.length > 0) {
				return {
					isValid: false,
					error: `Invalid choice IDs: ${invalidChoiceIds.join(", ")}`,
				};
			}

			return { isValid: true };
		} catch (error) {
			return {
				isValid: false,
				error: "Failed to validate question and choices",
			};
		}
	}
}
