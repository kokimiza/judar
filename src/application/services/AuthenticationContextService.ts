export interface AuthenticatedUser {
	userId: number;
	userName: string;
}

export interface AuthenticationContextService {
	getCurrentUser(): AuthenticatedUser | null;
	setCurrentUser(user: AuthenticatedUser): void;
}
