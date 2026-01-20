import type { UserRepository } from "../repositories/UserRepository";

export class UserDomainService {
	constructor(private readonly userRepository: UserRepository) {}

	async isUserNameAvailable(userName: string): Promise<boolean> {
		try {
			const existingUser = await this.userRepository.findByUserName(userName);
			return existingUser === null;
		} catch (error) {
			// データベースエラーの場合は重複チェックに失敗したとみなす
			return false;
		}
	}

	async validateUserName(
		userName: string,
	): Promise<{ isValid: boolean; error?: string }> {
		if (!userName || userName.trim().length === 0) {
			return { isValid: false, error: "User name cannot be empty" };
		}

		if (userName.length > 100) {
			return { isValid: false, error: "User name is too long" };
		}

		const isAvailable = await this.isUserNameAvailable(userName);
		if (!isAvailable) {
			return { isValid: false, error: "User name already exists" };
		}

		return { isValid: true };
	}
}
