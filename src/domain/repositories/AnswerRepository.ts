import type { Answer } from "../entities/Answer";

export interface AnswerRepository {
	saveAnswers(answers: Omit<Answer, "id" | "createdAt">[]): Promise<void>;
	getUnaggregatedAnswers(): Promise<Answer[]>;
	deleteAnswers(answerIds: number[]): Promise<void>;
	saveAggregatedAnswers(
		batchId: number,
		answers: Omit<Answer, "id" | "createdAt">[],
	): Promise<void>;

	// 日付関連のメソッド（インフラストラクチャレイヤーで実装）
	validateDateId(dateId: number): Promise<boolean>;
	getDateText(dateId: number): Promise<string | null>;
	getAvailableDates(): Promise<Array<{ dateId: number; dateText: string }>>;
}
