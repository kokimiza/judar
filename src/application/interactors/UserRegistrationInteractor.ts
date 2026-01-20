import { User } from "../../domain/entities/User";
import type { UserRepository } from "../../domain/repositories/UserRepository";
import type { AuthenticationService } from "../../domain/services/AuthenticationService";
import { UserDomainService } from "../../domain/services/UserDomainService";
import type {
	UserRegistrationRequest,
	UserRegistrationResponse,
} from "../dtos/UserRegistrationDto";
import type { UserRegistrationInputPort } from "../ports/input/UserRegistrationInputPort";
import type { UserRegistrationOutputPort } from "../ports/output/UserRegistrationOutputPort";

export class UserRegistrationInteractor implements UserRegistrationInputPort {
	private readonly userDomainService: UserDomainService;

	constructor(
		private readonly userRepository: UserRepository,
		private readonly outputPort: UserRegistrationOutputPort,
		private readonly authService: AuthenticationService,
	) {
		this.userDomainService = new UserDomainService(userRepository);
	}

	async register(
		request: UserRegistrationRequest,
	): Promise<UserRegistrationResponse> {
		try {
			// バリデーション
			if (!request.email || !request.password) {
				return this.outputPort.presentError("Email and password are required");
			}

			// ドメインサービスでバリデーション
			const validation = await this.userDomainService.validateUserName(
				request.userName,
			);

			if (!validation.isValid) {
				return this.outputPort.presentError(
					validation.error || "Invalid user name",
				);
			}

			// メールアドレス重複チェック
			const existingUser = await this.userRepository.findByEmail(request.email);
			if (existingUser) {
				return this.outputPort.presentError("Email already exists");
			}

			// パスワードハッシュ化（ドメインサービス経由）
			const { hash, salt } = await this.authService.hashPassword(
				request.password,
			);

			const userToCreate = User.create(
				request.userName,
				request.email,
				hash,
				salt,
			);
			const createdUser = await this.userRepository.save(userToCreate);

			return this.outputPort.presentSuccess(
				createdUser.userId,
				createdUser.userName,
				createdUser.email || "",
			);
		} catch (error) {
			console.error("User registration error:", error);
			return this.outputPort.presentError("User registration failed");
		}
	}
}
