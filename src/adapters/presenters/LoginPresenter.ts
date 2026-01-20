import type { LoginResponseDto } from "../../application/dtos/LoginDto";
import type { LoginPresenter as ILoginPresenter } from "../../application/interactors/LoginInteractor";

export class LoginPresenter implements ILoginPresenter {
	present(response: LoginResponseDto): Response {
		const status = response.success ? 200 : 401;

		return new Response(JSON.stringify(response), {
			status,
			headers: {
				"Content-Type": "application/json",
				"Access-Control-Allow-Origin": "*",
				"Access-Control-Allow-Methods": "POST, OPTIONS",
				"Access-Control-Allow-Headers": "Content-Type, Authorization",
			},
		});
	}
}
