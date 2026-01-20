import { Answer } from "../../domain/entities/Answer";
import type { AnswerRepository } from "../../domain/repositories/AnswerRepository";

interface RawAnswerRow {
	answer_id: number;
	user_id: number;
	question_id: number;
	choice_id: number;
	date_id: number;
	created_at: number;
}

export class D1AnswerRepository implements AnswerRepository {
	constructor(private readonly db: D1Database) {}

	async saveAnswers(
		answers: Omit<Answer, "id" | "createdAt">[],
	): Promise<void> {
		if (answers.length === 0) return;

		const stmt = this.db.prepare(
			`INSERT INTO raw_answers (user_id, question_id, choice_id, date_id, created_at)
       VALUES ${answers.map(() => "(?, ?, ?, ?, strftime('%s','now'))").join(", ")}`,
		);

		const bindValues: number[] = [];
		for (const answer of answers) {
			bindValues.push(
				answer.userId,
				answer.questionId,
				answer.choiceId,
				answer.dateId,
			);
		}

		await stmt.bind(...bindValues).run();
	}

	async getUnaggregatedAnswers(): Promise<Answer[]> {
		const stmt = this.db.prepare(`
      SELECT ra.*, sd.date_text
      FROM raw_answers ra
      JOIN m_survey_dates sd ON ra.date_id = sd.date_id
      ORDER BY ra.created_at ASC
    `);

		const { results } = await stmt.all();

		return results.map((row) => {
			const typedRow = row as unknown as RawAnswerRow & { date_text: string };
			return new Answer(
				typedRow.answer_id,
				typedRow.user_id,
				typedRow.question_id,
				typedRow.choice_id,
				typedRow.date_id,
				new Date(typedRow.created_at * 1000),
			);
		});
	}

	async deleteAnswers(answerIds: number[]): Promise<void> {
		if (answerIds.length === 0) return;

		const placeholders = answerIds.map(() => "?").join(",");
		const stmt = this.db.prepare(
			`DELETE FROM raw_answers WHERE answer_id IN (${placeholders})`,
		);

		await stmt.bind(...answerIds).run();
	}

	async saveAggregatedAnswers(
		batchId: number,
		answers: Omit<Answer, "id" | "createdAt">[],
	): Promise<void> {
		if (answers.length === 0) return;

		const stmt = this.db.prepare(
			`INSERT INTO processed_answers (user_id, question_id, choice_id, date_id, batch_id, created_at)
       VALUES ${answers.map(() => "(?, ?, ?, ?, ?, strftime('%s','now'))").join(", ")}`,
		);

		const bindValues: number[] = [];
		for (const answer of answers) {
			bindValues.push(
				answer.userId,
				answer.questionId,
				answer.choiceId,
				answer.dateId,
				batchId,
			);
		}

		await stmt.bind(...bindValues).run();
	}

	/**
	 * date_idの妥当性をチェックする
	 * m_survey_datesテーブルに存在するdate_idかどうかを確認
	 */
	async validateDateId(dateId: number): Promise<boolean> {
		const stmt = this.db.prepare(
			"SELECT 1 FROM m_survey_dates WHERE date_id = ? LIMIT 1",
		);
		const result = await stmt.bind(dateId).first();
		return result !== null;
	}

	/**
	 * date_idから日付テキストを取得する
	 */
	async getDateText(dateId: number): Promise<string | null> {
		const stmt = this.db.prepare(
			"SELECT date_text FROM m_survey_dates WHERE date_id = ? LIMIT 1",
		);
		const result = await stmt.bind(dateId).first<{ date_text: string }>();
		return result?.date_text || null;
	}

	/**
	 * 利用可能な調査日付一覧を取得する
	 */
	async getAvailableDates(): Promise<
		Array<{ dateId: number; dateText: string }>
	> {
		const stmt = this.db.prepare(
			"SELECT date_id, date_text FROM m_survey_dates ORDER BY date_id",
		);
		const { results } = await stmt.all<{
			date_id: number;
			date_text: string;
		}>();

		return results.map((row) => ({
			dateId: row.date_id,
			dateText: row.date_text,
		}));
	}
}
