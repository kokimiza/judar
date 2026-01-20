import type { UserRegistrationRequest } from "../../application/dtos/UserRegistrationDto";
import type { UserRegistrationInputPort } from "../../application/ports/input/UserRegistrationInputPort";

export class UserRegistrationController {
	constructor(private readonly inputPort: UserRegistrationInputPort) {}

	async handle(request: Request): Promise<Response> {
		try {
			const rawData: unknown = await request.json();

			// 型チェック
			if (
				typeof rawData !== "object" ||
				rawData === null ||
				!("userName" in rawData) ||
				typeof rawData.userName !== "string" ||
				!("email" in rawData) ||
				typeof rawData.email !== "string" ||
				!("password" in rawData) ||
				typeof rawData.password !== "string"
			) {
				return new Response(
					"Bad Request: userName, email, and password are required",
					{
						status: 400,
					},
				);
			}

			const dto: UserRegistrationRequest = {
				userName: rawData.userName,
				email: rawData.email,
				password: rawData.password,
			};

			const response = await this.inputPort.register(dto);

			const statusCode = response.status === "ok" ? 200 : 400;
			return new Response(JSON.stringify(response), {
				status: statusCode,
				headers: {
					"content-type": "application/json",
					"Access-Control-Allow-Origin": "*",
					"Access-Control-Allow-Methods": "POST, OPTIONS",
					"Access-Control-Allow-Headers": "Content-Type, Authorization",
				},
			});
		} catch (error) {
			return new Response(
				JSON.stringify({ status: "error", message: "Internal server error" }),
				{
					status: 500,
					headers: { "content-type": "application/json" },
				},
			);
		}
	}
}
