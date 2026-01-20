import { User } from "../../domain/entities/User";
import type { UserRepository } from "../../domain/repositories/UserRepository";

export class D1UserRepository implements UserRepository {
	constructor(private readonly db: D1Database) {}

	async save(
		user: Omit<User, "userId" | "createdAt" | "updatedAt">,
	): Promise<User> {
		const stmt = this.db.prepare(
			`INSERT INTO m_users (user_name, email, password_hash, salt, created_at, updated_at)
       VALUES (?, ?, ?, ?, strftime('%s','now'), strftime('%s','now'))
       RETURNING user_id, user_name, email, password_hash, salt, created_at, updated_at`,
		);

		const result = await stmt
			.bind(user.userName, user.email, user.passwordHash, user.salt)
			.first();

		if (!result) {
			throw new Error("Failed to create user");
		}

		return new User(
			result.user_id as number,
			result.user_name as string,
			result.email as string | null,
			result.password_hash as string | null,
			result.salt as string | null,
			new Date((result.created_at as number) * 1000),
			new Date((result.updated_at as number) * 1000),
		);
	}

	async findByUserName(userName: string): Promise<User | null> {
		const stmt = this.db.prepare(
			`SELECT user_id, user_name, email, password_hash, salt, created_at, updated_at 
       FROM m_users 
       WHERE user_name = ?`,
		);

		const result = await stmt.bind(userName).first();

		if (!result) {
			return null;
		}

		return new User(
			result.user_id as number,
			result.user_name as string,
			result.email as string | null,
			result.password_hash as string | null,
			result.salt as string | null,
			new Date((result.created_at as number) * 1000),
			new Date((result.updated_at as number) * 1000),
		);
	}

	async findByEmail(email: string): Promise<User | null> {
		const stmt = this.db.prepare(
			`SELECT user_id, user_name, email, password_hash, salt, created_at, updated_at 
       FROM m_users 
       WHERE email = ?`,
		);

		const result = await stmt.bind(email).first();

		if (!result) {
			return null;
		}

		return new User(
			result.user_id as number,
			result.user_name as string,
			result.email as string | null,
			result.password_hash as string | null,
			result.salt as string | null,
			new Date((result.created_at as number) * 1000),
			new Date((result.updated_at as number) * 1000),
		);
	}

	async findById(userId: number): Promise<User | null> {
		const stmt = this.db.prepare(
			`SELECT user_id, user_name, email, password_hash, salt, created_at, updated_at 
       FROM m_users 
       WHERE user_id = ?`,
		);

		const result = await stmt.bind(userId).first();

		if (!result) {
			return null;
		}

		return new User(
			result.user_id as number,
			result.user_name as string,
			result.email as string | null,
			result.password_hash as string | null,
			result.salt as string | null,
			new Date((result.created_at as number) * 1000),
			new Date((result.updated_at as number) * 1000),
		);
	}
}
