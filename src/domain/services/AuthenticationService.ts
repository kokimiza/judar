export interface AuthenticationService {
	hashPassword(password: string): Promise<{ hash: string; salt: string }>;
	verifyPassword(
		password: string,
		hash: string,
		salt: string,
	): Promise<boolean>;
	generateToken(userId: number, userName: string): Promise<string>;
	verifyToken(
		token: string,
	): Promise<{ userId: number; userName: string } | null>;
}
