import type { AuthenticationContextService } from "../../application/services/AuthenticationContextService";
import type { AuthenticationService } from "../../domain/services/AuthenticationService";

export interface AuthenticatedRequest extends Request {
	user?: { userId: number; userName: string };
}

export class AuthMiddleware {
	constructor(
		private authService: AuthenticationService,
		private authContext: AuthenticationContextService,
	) {}

	async authenticate(
		request: Request,
	): Promise<{ success: boolean; response?: Response }> {
		const authHeader = request.headers.get("Authorization");

		if (!authHeader || !authHeader.startsWith("Bearer ")) {
			return {
				success: false,
				response: new Response(
					JSON.stringify({ error: "Missing or invalid authorization header" }),
					{
						status: 401,
						headers: { "Content-Type": "application/json" },
					},
				),
			};
		}

		const token = authHeader.substring(7); // Remove 'Bearer ' prefix
		const user = await this.authService.verifyToken(token);

		if (!user) {
			return {
				success: false,
				response: new Response(
					JSON.stringify({ error: "Invalid or expired token" }),
					{
						status: 401,
						headers: { "Content-Type": "application/json" },
					},
				),
			};
		}

		// 認証コンテキストに現在のユーザーを設定
		this.authContext.setCurrentUser(user);

		return {
			success: true,
		};
	}
}
