export class Question {
	constructor(
		public readonly id: number,
		public readonly text: string,
		public readonly createdAt: Date,
		public readonly updatedAt: Date,
	) {}

	static create(
		text: string,
	): Omit<Question, "id" | "createdAt" | "updatedAt"> {
		return { text };
	}
}
