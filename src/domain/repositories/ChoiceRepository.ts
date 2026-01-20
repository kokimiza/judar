import type { Choice } from "../entities/Choice";

export interface ChoiceRepository {
	saveChoices(
		choices: Omit<Choice, "id" | "createdAt" | "updatedAt">[],
	): Promise<Choice[]>;
	findByQuestionId(questionId: number): Promise<Choice[]>;
	validateChoiceValues(questionId: number, values: number[]): Promise<boolean>;
}
