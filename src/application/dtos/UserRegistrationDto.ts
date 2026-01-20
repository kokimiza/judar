export interface UserRegistrationRequest {
	userName: string;
	email: string;
	password: string;
}

export interface UserRegistrationResponse {
	status: "ok" | "error";
	userId?: number;
	userName?: string;
	email?: string;
	message?: string;
}
