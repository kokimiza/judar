export class User {
	constructor(
		public readonly userId: number,
		public readonly userName: string,
		public readonly email: string | null,
		public readonly passwordHash: string | null,
		public readonly salt: string | null,
		public readonly createdAt: Date,
		public readonly updatedAt: Date,
	) {}

	static create(
		userName: string,
		email?: string,
		passwordHash?: string,
		salt?: string,
	): Omit<User, "userId" | "createdAt" | "updatedAt"> {
		return {
			userName,
			email: email || null,
			passwordHash: passwordHash || null,
			salt: salt || null,
		};
	}
}
