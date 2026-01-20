import { Matrix } from "ml-matrix";
import { PCA } from "ml-pca";
import type { Answer } from "../entities/Answer";

export interface ClusterResult {
	userId: number;
	clusterNo: number;
	distance: number;
}

export interface StatisticalSummary {
	totalUsers: number;
	totalAnswers: number;
	questionsAnalyzed: number;
	clusterCount: number;
	silhouetteScore: number;
	inertia: number;
}

const TYPE_BITS = 16;
const PCA_MAX_COMPONENTS = 16;
const QUANT_SCALE = 2.0;

export class StatisticalAnalysisService {
	private cache = new Map<number, { typeId: number; distance: number }>();

	async performClustering(answers: Answer[]): Promise<{
		clusters: ClusterResult[];
		summary: StatisticalSummary;
	}> {
		if (answers.length === 0) {
			return {
				clusters: [],
				summary: {
					totalUsers: 0,
					totalAnswers: 0,
					questionsAnalyzed: 0,
					clusterCount: 0,
					silhouetteScore: 0,
					inertia: 0,
				},
			};
		}

		const { userMatrix, userIds } = this.createUserMatrix(answers);
		const reduced = this.applyPCA(userMatrix);
		const normalized = this.normalizeRows(reduced);

		const clusters: ClusterResult[] = userIds.map((userId, i) => {
			const row = normalized.getRow(i);
			const key = this.vectorToIntKey(row);

			let entry = this.cache.get(key);
			if (!entry) {
				entry = this.quantizeVector(row);
				this.cache.set(key, entry);
			}

			const { typeId, distance } = entry;
			return { userId, clusterNo: typeId, distance };
		});

		const inertia = clusters.reduce((sum, c) => sum + c.distance ** 2, 0);

		return {
			clusters,
			summary: {
				totalUsers: userIds.length,
				totalAnswers: answers.length,
				questionsAnalyzed: userMatrix.columns,
				clusterCount: 1 << TYPE_BITS,
				silhouetteScore: 0, // 意味を失うため固定
				inertia,
			},
		};
	}

	private createUserMatrix(answers: Answer[]): {
		userMatrix: Matrix;
		userIds: number[];
	} {
		const userMap = new Map<number, Map<number, number>>();
		const questions = new Set<number>();

		for (const a of answers) {
			if (!userMap.has(a.userId)) userMap.set(a.userId, new Map());
			userMap.get(a.userId)?.set(a.questionId, a.choiceId);
			questions.add(a.questionId);
		}

		const qList = [...questions].sort((a, b) => a - b);
		const userIds = [...userMap.keys()].sort((a, b) => a - b);

		const data = userIds.map((uid) =>
			qList.map((q) => userMap.get(uid)?.get(q) ?? 0),
		);

		return { userMatrix: new Matrix(data), userIds };
	}

	private applyPCA(matrix: Matrix): Matrix {
		if (matrix.rows < 2 || matrix.columns < 2) return matrix;
		const nComponents = Math.min(
			PCA_MAX_COMPONENTS,
			matrix.rows - 1,
			matrix.columns,
		);
		if (nComponents < 2) return matrix;

		const pca = new PCA(matrix.to2DArray(), { center: true, scale: false });
		return new Matrix(pca.predict(matrix.to2DArray(), { nComponents }));
	}

	private normalizeRows(matrix: Matrix): Matrix {
		const result = matrix.clone();
		for (let i = 0; i < result.rows; i++) {
			const row = result.getRow(i);
			const norm = Math.sqrt(row.reduce((sum, v) => sum + v * v, 0));
			if (norm === 0) continue;
			for (let j = 0; j < row.length; j++) row[j] /= norm;
			result.setRow(i, row);
		}
		return result;
	}

	private vectorToIntKey(v: number[]): number {
		let bits = 0;
		for (let i = 0; i < TYPE_BITS; i++) {
			bits = (bits << 1) | (v[i % v.length] >= 0 ? 1 : 0);
		}
		return bits + 1; // clusterNoは1以上
	}

	private quantizeVector(v: number[]): { typeId: number; distance: number } {
		let dist = 0;
		for (let i = 0; i < TYPE_BITS; i++) {
			const x = v[i % v.length] * QUANT_SCALE;
			const bit = x >= 0 ? 1 : 0;
			const center = bit ? 1 : -1;
			dist += (x - center) ** 2;
		}
		return {
			typeId: this.vectorToIntKey(v),
			distance: Math.sqrt(dist / TYPE_BITS),
		};
	}
}
