import type { Answer } from "../domain/entities/Answer";

export interface GenerateRandomAnswersOptions {
	users: number;
	answersPerUser: number;
	seed?: number;
	maxQuestions?: number;
	maxChoices?: number;
}

export function generateRandomAnswers(
	options: GenerateRandomAnswersOptions,
): Answer[] {
	const {
		users,
		answersPerUser,
		seed = 42,
		maxQuestions = 10,
		maxChoices = 4,
	} = options;

	// Simple seeded random number generator for reproducible tests
	let seedValue = seed;
	const random = () => {
		seedValue = (seedValue * 9301 + 49297) % 233280;
		return seedValue / 233280;
	};

	const answers: Answer[] = [];
	let answerId = 1;

	for (let userId = 1; userId <= users; userId++) {
		for (let i = 0; i < answersPerUser; i++) {
			const questionId = Math.floor(random() * maxQuestions) + 1;
			const choiceId = Math.floor(random() * maxChoices) + 1;
			const dateId = 20250101; // Fixed date for simplicity

			answers.push({
				id: answerId++,
				userId,
				questionId,
				choiceId,
				dateId,
				createdAt: new Date(),
			});
		}
	}

	return answers;
}
