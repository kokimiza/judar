import type { UserRegistrationResponse } from "../../dtos/UserRegistrationDto";

export interface UserRegistrationOutputPort {
	presentSuccess(
		userId: number,
		userName: string,
		email: string,
	): UserRegistrationResponse;
	presentError(message: string): UserRegistrationResponse;
}
