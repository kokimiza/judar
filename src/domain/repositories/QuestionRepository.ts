import type { Question } from "../entities/Question";

export interface QuestionRepository {
	save(
		question: Omit<Question, "id" | "createdAt" | "updatedAt">,
	): Promise<Question>;
	findByText(text: string): Promise<Question | null>;
}
