import type { User } from "../entities/User";

export interface UserRepository {
	save(user: Omit<User, "userId" | "createdAt" | "updatedAt">): Promise<User>;
	findByUserName(userName: string): Promise<User | null>;
	findByEmail(email: string): Promise<User | null>;
	findById(userId: number): Promise<User | null>;
}
