import type { LoginRequestDto } from "../../application/dtos/LoginDto";
import type { LoginInteractor } from "../../application/interactors/LoginInteractor";

export class LoginController {
	constructor(private loginInteractor: LoginInteractor) {}

	async handle(request: Request): Promise<Response> {
		try {
			const body: LoginRequestDto = await request.json();

			// バリデーション
			if (!body.email || !body.password) {
				return new Response(
					JSON.stringify({
						success: false,
						error: "Email and password are required",
					}),
					{
						status: 400,
						headers: { "Content-Type": "application/json" },
					},
				);
			}

			return await this.loginInteractor.execute(body);
		} catch (error) {
			return new Response(
				JSON.stringify({
					success: false,
					error: "Invalid request body",
				}),
				{
					status: 400,
					headers: { "Content-Type": "application/json" },
				},
			);
		}
	}
}
