import type { QuestionCreationRequest } from "../../application/dtos/QuestionCreationDto";
import type { QuestionCreationInputPort } from "../../application/ports/input/QuestionCreationInputPort";

export class QuestionCreationController {
	constructor(private readonly inputPort: QuestionCreationInputPort) {}

	async handle(request: Request): Promise<Response> {
		try {
			const rawData: unknown = await request.json();

			// 型チェック
			if (
				typeof rawData !== "object" ||
				rawData === null ||
				!("questionText" in rawData) ||
				!("choices" in rawData) ||
				typeof rawData.questionText !== "string" ||
				!Array.isArray(rawData.choices)
			) {
				return new Response(
					"Bad Request: questionText and choices array are required",
					{ status: 400 },
				);
			}

			const data = rawData as {
				questionText: string;
				choices: Array<{
					text: string;
					value: number | string;
				}>;
			};

			// 選択肢の形式チェック
			for (const choice of data.choices) {
				if (
					!("text" in choice) ||
					!("value" in choice) ||
					typeof choice.text !== "string"
				) {
					return new Response(
						"Bad Request: each choice must have text and value",
						{ status: 400 },
					);
				}
			}

			// DTOに変換
			const dto: QuestionCreationRequest = {
				questionText: data.questionText.trim(),
				choices: data.choices.map((choice) => ({
					text: choice.text.trim(),
					value: Number(choice.value),
				})),
			};

			const response = await this.inputPort.createQuestion(dto);

			const statusCode = response.status === "ok" ? 201 : 400;
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
