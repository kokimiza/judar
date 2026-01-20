import type { AnswerSubmissionRequest } from "../../application/dtos/AnswerSubmissionDto";
import type { AnswerSubmissionInputPort } from "../../application/ports/input/AnswerSubmissionInputPort";

export class AnswerSubmissionController {
	constructor(private readonly inputPort: AnswerSubmissionInputPort) {}

	async handle(request: Request): Promise<Response> {
		try {
			const rawData: unknown = await request.json();

			// 型チェック
			if (
				typeof rawData !== "object" ||
				rawData === null ||
				!("user_id" in rawData) ||
				!("answers" in rawData) ||
				!Array.isArray(rawData.answers)
			) {
				return new Response(
					"Bad Request: user_id and answers array are required",
					{ status: 400 },
				);
			}

			const data = rawData as {
				user_id: number | string;
				answers: Array<{
					question_id: number | string;
					choice_id: number | string;
				}>;
			};

			// 回答の形式チェック
			for (const answer of data.answers) {
				if (!("question_id" in answer) || !("choice_id" in answer)) {
					return new Response(
						"Bad Request: each answer must have question_id and choice_id",
						{ status: 400 },
					);
				}
			}

			// DTOに変換
			const dto: AnswerSubmissionRequest = {
				userId: Number(data.user_id),
				answers: data.answers.map((answer) => ({
					questionId: Number(answer.question_id),
					choiceId: Number(answer.choice_id),
				})),
			};

			const response = await this.inputPort.submit(dto);

			const statusCode = response.status === "ok" ? 200 : 400;
			return new Response(JSON.stringify(response), {
				status: statusCode,
				headers: { "content-type": "application/json" },
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
