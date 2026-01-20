import { Question } from "../../domain/entities/Question";
import type { QuestionRepository } from "../../domain/repositories/QuestionRepository";

export class D1QuestionRepository implements QuestionRepository {
	constructor(private readonly db: D1Database) {}

	async save(
		question: Omit<Question, "id" | "createdAt" | "updatedAt">,
	): Promise<Question> {
		const stmt = this.db.prepare(
			`INSERT INTO m_questions (question_text, created_at, updated_at)
       VALUES (?, strftime('%s','now'), strftime('%s','now'))
       RETURNING question_id, question_text, created_at, updated_at`,
		);

		const result = await stmt.bind(question.text).first();

		if (!result) {
			throw new Error("Failed to create question");
		}

		return new Question(
			result.question_id as number,
			result.question_text as string,
			new Date((result.created_at as number) * 1000),
			new Date((result.updated_at as number) * 1000),
		);
	}

	async findByText(text: string): Promise<Question | null> {
		const stmt = this.db.prepare(
			`SELECT question_id, question_text, created_at, updated_at 
       FROM m_questions 
       WHERE question_text = ?`,
		);

		const result = await stmt.bind(text).first();

		if (!result) {
			return null;
		}

		return new Question(
			result.question_id as number,
			result.question_text as string,
			new Date((result.created_at as number) * 1000),
			new Date((result.updated_at as number) * 1000),
		);
	}
}
