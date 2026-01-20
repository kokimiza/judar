import type { UserRegistrationResponse } from "../../application/dtos/UserRegistrationDto";
import type { UserRegistrationOutputPort } from "../../application/ports/output/UserRegistrationOutputPort";

export class UserRegistrationPresenter implements UserRegistrationOutputPort {
	presentSuccess(
		userId: number,
		userName: string,
		email: string,
	): UserRegistrationResponse {
		return {
			status: "ok",
			userId,
			userName,
			email,
		};
	}

	presentError(message: string): UserRegistrationResponse {
		return {
			status: "error",
			message,
		};
	}
}
