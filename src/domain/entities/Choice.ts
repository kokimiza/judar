export class Choice {
	constructor(
		public readonly id: number,
		public readonly questionId: number,
		public readonly text: string,
		public readonly value: number,
		public readonly createdAt: Date,
		public readonly updatedAt: Date,
	) {}

	static create(
		questionId: number,
		text: string,
		value: number,
	): Omit<Choice, "id" | "createdAt" | "updatedAt"> {
		return { questionId, text, value };
	}
}
