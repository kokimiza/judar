import type { AuthenticationService } from "../../domain/services/AuthenticationService";
import { JwtAuth } from "./JwtAuth";
import { PasswordHash } from "./PasswordHash";

export class CloudflareAuthenticationService implements AuthenticationService {
	private jwtAuth: JwtAuth;

	constructor(jwtSecret: string) {
		this.jwtAuth = new JwtAuth(jwtSecret);
	}

	async hashPassword(
		password: string,
	): Promise<{ hash: string; salt: string }> {
		const salt = PasswordHash.generateSalt();
		const hash = await PasswordHash.hash(password, salt);
		return { hash, salt };
	}

	async verifyPassword(
		password: string,
		hash: string,
		salt: string,
	): Promise<boolean> {
		return await PasswordHash.verify(password, salt, hash);
	}

	async generateToken(userId: number, userName: string): Promise<string> {
		return await this.jwtAuth.generateToken(userId, userName);
	}

	async verifyToken(
		token: string,
	): Promise<{ userId: number; userName: string } | null> {
		const payload = await this.jwtAuth.verifyToken(token);
		if (!payload) {
			return null;
		}
		return {
			userId: payload.userId,
			userName: payload.userName,
		};
	}
}
