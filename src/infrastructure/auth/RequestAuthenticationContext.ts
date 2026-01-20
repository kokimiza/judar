import type {
	AuthenticatedUser,
	AuthenticationContextService,
} from "../../application/services/AuthenticationContextService";

export class RequestAuthenticationContext
	implements AuthenticationContextService
{
	private currentUser: AuthenticatedUser | null = null;

	getCurrentUser(): AuthenticatedUser | null {
		return this.currentUser;
	}

	setCurrentUser(user: AuthenticatedUser): void {
		this.currentUser = user;
	}
}
