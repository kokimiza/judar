export class Answer {
	constructor(
		public readonly id: number,
		public readonly userId: number,
		public readonly questionId: number,
		public readonly choiceId: number,
		public readonly dateId: number,
		public readonly createdAt: Date,
	) {}

	static create(
		userId: number,
		questionId: number,
		choiceId: number,
		dateId: number,
	): Omit<Answer, "id" | "createdAt"> {
		return { userId, questionId, choiceId, dateId };
	}
}
