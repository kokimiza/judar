import { Choice } from "../../domain/entities/Choice";
import type { ChoiceRepository } from "../../domain/repositories/ChoiceRepository";

export class D1ChoiceRepository implements ChoiceRepository {
	constructor(private readonly db: D1Database) {}

	async saveChoices(
		choices: Omit<Choice, "id" | "createdAt" | "updatedAt">[],
	): Promise<Choice[]> {
		if (choices.length === 0) return [];

		const stmt = this.db.prepare(
			`INSERT INTO m_choices (question_id, choice_text, choice_value, created_at, updated_at)
       VALUES ${choices.map(() => "(?, ?, ?, strftime('%s','now'), strftime('%s','now'))").join(", ")}
       RETURNING choice_id, question_id, choice_text, choice_value, created_at, updated_at`,
		);

		const bindValues: (number | string)[] = [];
		for (const choice of choices) {
			bindValues.push(choice.questionId, choice.text, choice.value);
		}

		const { results } = await stmt.bind(...bindValues).all();

		return results.map(
			(row: any) =>
				new Choice(
					row.choice_id,
					row.question_id,
					row.choice_text,
					row.choice_value,
					new Date(row.created_at * 1000),
					new Date(row.updated_at * 1000),
				),
		);
	}

	async findByQuestionId(questionId: number): Promise<Choice[]> {
		const stmt = this.db.prepare(
			`SELECT choice_id, question_id, choice_text, choice_value, created_at, updated_at
       FROM m_choices 
       WHERE question_id = ?
       ORDER BY choice_value ASC`,
		);

		const { results } = await stmt.bind(questionId).all();

		return results.map(
			(row: any) =>
				new Choice(
					row.choice_id,
					row.question_id,
					row.choice_text,
					row.choice_value,
					new Date(row.created_at * 1000),
					new Date(row.updated_at * 1000),
				),
		);
	}

	async validateChoiceValues(
		questionId: number,
		values: number[],
	): Promise<boolean> {
		if (values.length === 0) return true;

		const placeholders = values.map(() => "?").join(",");
		const stmt = this.db.prepare(
			`SELECT COUNT(*) as count 
       FROM m_choices 
       WHERE question_id = ? AND choice_value IN (${placeholders})`,
		);

		const result = await stmt.bind(questionId, ...values).first();

		return (result?.count as number) === values.length;
	}
}
