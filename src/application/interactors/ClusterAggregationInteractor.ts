import { Cluster } from "../../domain/entities/Cluster";
import type { AnswerRepository } from "../../domain/repositories/AnswerRepository";
import type { BatchRepository } from "../../domain/repositories/BatchRepository";
import type { ClusterRepository } from "../../domain/repositories/ClusterRepository";
import { StatisticalAnalysisService } from "../../domain/services/StatisticalAnalysisService";
import type {
	ClusterAggregationRequest,
	ClusterAggregationResponse,
} from "../dtos/ClusterAggregationDto";
import type { ClusterAggregationInputPort } from "../ports/input/ClusterAggregationInputPort";
import type { ClusterAggregationOutputPort } from "../ports/output/ClusterAggregationOutputPort";

export class ClusterAggregationInteractor
	implements ClusterAggregationInputPort
{
	private readonly statisticalAnalysisService: StatisticalAnalysisService;

	constructor(
		private readonly answerRepository: AnswerRepository,
		private readonly clusterRepository: ClusterRepository,
		private readonly batchRepository: BatchRepository,
		private readonly outputPort: ClusterAggregationOutputPort,
	) {
		this.statisticalAnalysisService = new StatisticalAnalysisService();
	}

	async aggregate(
		_request: ClusterAggregationRequest,
	): Promise<ClusterAggregationResponse> {
		let batchId: number | null = null;

		try {
			// 1. バッチを開始（pending状態で記録）
			batchId = await this.batchRepository.startBatch("cluster_aggregation");
			console.log(`Batch ${batchId}: Started cluster aggregation process`);

			// 2. 未集計データを取得
			const unaggregatedAnswers =
				await this.answerRepository.getUnaggregatedAnswers();

			if (unaggregatedAnswers.length === 0) {
				// 処理対象データが0件の場合：
				// - バッチマスタのみ更新（処理件数0で完了状態に）
				// - 実際のデータ処理は行わない
				// - 実行履歴は残しつつ、安全に処理を終了
				await this.batchRepository.completeBatch(batchId, 0);
				console.log(
					`Batch ${batchId}: No data to process, completed with 0 records`,
				);
				return this.outputPort.presentSuccess(0);
			}

			console.log(
				`Batch ${batchId}: Processing ${unaggregatedAnswers.length} unaggregated answers`,
			);

			// 3. 統計解析とクラスタリングを実行
			const { clusters: clusterResults, summary } =
				await this.statisticalAnalysisService.performClustering(
					unaggregatedAnswers,
				);

			// 4. 集計済み回答データを準備
			const aggregatedAnswers = unaggregatedAnswers.map((answer) => ({
				userId: answer.userId,
				questionId: answer.questionId,
				choiceId: answer.choiceId,
				dateId: answer.dateId,
			}));

			// 5. クラスターデータを準備
			const clusters = clusterResults.map((result) =>
				Cluster.create(batchId as number, result.userId, result.clusterNo),
			);

			// 6. トランザクション的にデータを保存
			try {
				// 集計済みテーブルに保存
				await this.answerRepository.saveAggregatedAnswers(
					batchId as number,
					aggregatedAnswers,
				);

				// クラスターテーブルに保存
				await this.clusterRepository.saveClusters(clusters);

				// 成功した場合のみ元データを削除
				const answerIds = unaggregatedAnswers.map((answer) => answer.id);
				await this.answerRepository.deleteAnswers(answerIds);

				// バッチを完了状態に更新
				await this.batchRepository.completeBatch(
					batchId as number,
					unaggregatedAnswers.length,
				);
				console.log(
					`Batch ${batchId}: Successfully completed processing ${unaggregatedAnswers.length} records`,
				);

				// 成功レスポンス（統計情報付き）
				return this.outputPort.presentSuccess(
					unaggregatedAnswers.length,
					summary,
				);
			} catch (saveError) {
				// 保存に失敗した場合はバッチを失敗状態に更新
				console.error(`Batch ${batchId}: Failed to save data:`, saveError);
				await this.batchRepository.failBatch(batchId as number);
				throw new Error(`Failed to save aggregated data: ${saveError}`);
			}
		} catch (error) {
			// バッチが作成されている場合は失敗状態に更新
			if (batchId !== null) {
				try {
					await this.batchRepository.failBatch(batchId);
					console.error(
						`Batch ${batchId}: Marked as failed due to error:`,
						error,
					);
				} catch (batchError) {
					// バッチ更新エラーはログに記録するが、元のエラーを優先
					console.error("Failed to update batch status:", batchError);
				}
			}

			const errorMessage =
				error instanceof Error ? error.message : "Unknown error occurred";
			console.error(`Cluster aggregation failed: ${errorMessage}`);
			return this.outputPort.presentError(
				`Cluster aggregation failed: ${errorMessage}`,
			);
		}
	}
}
