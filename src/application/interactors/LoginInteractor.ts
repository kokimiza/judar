import type { UserRepository } from "../../domain/repositories/UserRepository";
import type { AuthenticationService } from "../../domain/services/AuthenticationService";
import type { LoginRequestDto, LoginResponseDto } from "../dtos/LoginDto";

export interface LoginPresenter {
	present(response: LoginResponseDto): Response;
}

export class LoginInteractor {
	constructor(
		private userRepository: UserRepository,
		private presenter: LoginPresenter,
		private authService: AuthenticationService,
	) {}

	async execute(request: LoginRequestDto): Promise<Response> {
		try {
			// メールアドレスでユーザー検索
			const user = await this.userRepository.findByEmail(request.email);

			if (!user) {
				return this.presenter.present({
					success: false,
					error: "Invalid email or password",
				});
			}

			// パスワード検証（ドメインサービス経由）
			const isValidPassword = await this.authService.verifyPassword(
				request.password,
				user.passwordHash || "",
				user.salt || "",
			);

			if (!isValidPassword) {
				return this.presenter.present({
					success: false,
					error: "Invalid email or password",
				});
			}

			// JWT生成（ドメインサービス経由）
			const token = await this.authService.generateToken(
				user.userId,
				user.userName,
			);

			return this.presenter.present({
				success: true,
				token,
				user: {
					userId: user.userId,
					userName: user.userName,
					email: user.email || "",
				},
			});
		} catch (error) {
			console.error("Login error:", error);
			return this.presenter.present({
				success: false,
				error: "Login failed",
			});
		}
	}
}
