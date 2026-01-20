import type {
	UserRegistrationRequest,
	UserRegistrationResponse,
} from "../../dtos/UserRegistrationDto";

export interface UserRegistrationInputPort {
	register(request: UserRegistrationRequest): Promise<UserRegistrationResponse>;
}
