import { describe, expect, it } from "vitest";
import type { Answer } from "../domain/entities/Answer";
import { StatisticalAnalysisService } from "../domain/services/StatisticalAnalysisService";
import { generateRandomAnswers } from "./testUtils";

const service = new StatisticalAnalysisService();

function answer(
	userId: number,
	questionId: number,
	choiceId: number,
	dateId = 20250101,
): Answer {
	return {
		id: 0,
		userId,
		questionId,
		choiceId,
		dateId,
		createdAt: new Date(),
	};
}

describe("StatisticalAnalysisService.performClustering", () => {
	it("空配列を渡すと空結果を返す", async () => {
		const result = await service.performClustering([]);
		expect(result.clusters).toHaveLength(0);
		expect(result.summary.totalUsers).toBe(0);
		expect(result.summary.clusterCount).toBe(0);
	});

	it("単一ユーザーでもクラッシュしない", async () => {
		const result = await service.performClustering([
			answer(1, 1, 2),
			answer(1, 2, 1),
		]);
		expect(result.summary.totalUsers).toBe(1);
		expect(result.clusters).toHaveLength(1);
		// clusterNo は単一ユーザーの場合でも量子化ルールで決定される
		expect(result.clusters[0].clusterNo).toBeGreaterThanOrEqual(1);
	});

	it("複数ユーザー・質問でクラスタリングされる", async () => {
		const answers: Answer[] = [
			answer(1, 1, 1),
			answer(1, 2, 1),
			answer(2, 1, 1),
			answer(2, 2, 2),
			answer(3, 1, 4),
			answer(3, 2, 4),
		];
		const result = await service.performClustering(answers);
		expect(result.summary.totalUsers).toBe(3);
		expect(result.summary.totalAnswers).toBe(6);
		expect(result.summary.questionsAnalyzed).toBe(2);
		expect(result.clusters.length).toBe(3);
	});

	it("回答数が極端に違うユーザーでも動く", async () => {
		const answers: Answer[] = [];
		for (let q = 1; q <= 20; q++) answers.push(answer(1, q, (q % 4) + 1));
		answers.push(answer(2, 1, 2));
		const result = await service.performClustering(answers);
		expect(result.summary.totalUsers).toBe(2);
		expect(result.clusters.length).toBe(2);
	});

	it("clusterNo は常に 1 以上で安定", async () => {
		const answers: Answer[] = [
			answer(1, 1, 1),
			answer(2, 1, 2),
			answer(3, 1, 3),
			answer(4, 1, 4),
		];
		const result = await service.performClustering(answers);
		const k = result.summary.clusterCount;
		for (const c of result.clusters) {
			expect(c.clusterNo).toBeGreaterThanOrEqual(1);
			expect(c.clusterNo).toBeLessThanOrEqual(k);
		}
	});

	it("distance は有限", async () => {
		const answers: Answer[] = [
			answer(1, 1, 1),
			answer(2, 1, 2),
			answer(3, 1, 3),
			answer(4, 1, 4),
		];
		const result = await service.performClustering(answers);
		for (const c of result.clusters) {
			expect(Number.isFinite(c.distance)).toBe(true);
		}
	});

	it("silhouetteScore と inertia は有限", async () => {
		const answers = generateRandomAnswers({
			users: 50,
			answersPerUser: 50,
			seed: 123,
		});
		const result = await service.performClustering(answers);
		expect(Number.isFinite(result.summary.silhouetteScore)).toBe(true);
		expect(Number.isFinite(result.summary.inertia)).toBe(true);
	});

	it("同一データなら clusterNo は安定", async () => {
		const answers = generateRandomAnswers({
			users: 7,
			answersPerUser: 280,
			seed: 2,
		});
		const r1 = await service.performClustering(answers);
		const r2 = await service.performClustering(answers);
		const map1 = new Map(r1.clusters.map((c) => [c.userId, c.clusterNo]));
		const map2 = new Map(r2.clusters.map((c) => [c.userId, c.clusterNo]));
		for (const [userId, clusterNo1] of map1.entries()) {
			const clusterNo2 = map2.get(userId);
			expect(clusterNo2).toBe(clusterNo1);
		}
	});

	it("全回答同一ユーザーでも distance は有限で計算可能", async () => {
		const answers: Answer[] = [
			answer(1, 1, 1),
			answer(1, 2, 2),
			answer(2, 1, 1),
			answer(2, 2, 2),
			answer(3, 1, 1),
			answer(3, 2, 2),
		];
		const result = await service.performClustering(answers);

		for (const c of result.clusters) {
			expect(Number.isFinite(c.distance)).toBe(true);
			expect(c.distance).toBeGreaterThanOrEqual(0);
			expect(c.distance).toBeLessThanOrEqual(1); // TYPE_BITS による量子化誤差を許容
		}
	});

	it("疎データでも安定してクラスタリングされる", async () => {
		const answers: Answer[] = [];
		for (let u = 1; u <= 10; u++) {
			if (u % 2 === 0) answers.push(answer(u, 1, 1));
			else answers.push(answer(u, 1, 1), answer(u, 2, 2));
		}
		const result = await service.performClustering(answers);
		expect(result.summary.totalUsers).toBe(10);
		expect(result.clusters.every((c) => Number.isFinite(c.distance))).toBe(
			true,
		);
	});

	it("clusterNo は 1 以上 TYPE_BITS の範囲内", async () => {
		const answers = generateRandomAnswers({
			users: 100,
			answersPerUser: 10,
			seed: 99,
		});
		const result = await service.performClustering(answers);
		for (const c of result.clusters) {
			expect(c.clusterNo).toBeGreaterThanOrEqual(1);
			expect(c.clusterNo).toBeLessThanOrEqual(2 ** 16);
		}
	});
});
