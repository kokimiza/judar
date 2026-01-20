export interface LoginRequestDto {
	email: string;
	password: string;
}

export interface LoginResponseDto {
	success: boolean;
	token?: string;
	user?: {
		userId: number;
		userName: string;
		email: string;
	};
	error?: string;
}
