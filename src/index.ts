// Infrastructure
import { AnswerSubmissionController } from "./adapters/controllers/AnswerSubmissionController";
import { ClusterAggregationController } from "./adapters/controllers/ClusterAggregationController";
import { LoginController } from "./adapters/controllers/LoginController";
import { QuestionCreationController } from "./adapters/controllers/QuestionCreationController";
// Controllers
import { UserRegistrationController } from "./adapters/controllers/UserRegistrationController";
import { AnswerSubmissionPresenter } from "./adapters/presenters/AnswerSubmissionPresenter";
import { ClusterAggregationPresenter } from "./adapters/presenters/ClusterAggregationPresenter";
import { LoginPresenter } from "./adapters/presenters/LoginPresenter";
// Presenters
import { QuestionCreationPresenter } from "./adapters/presenters/QuestionCreationPresenter";
import { UserRegistrationPresenter } from "./adapters/presenters/UserRegistrationPresenter";
import { AnswerSubmissionInteractor } from "./application/interactors/AnswerSubmissionInteractor";
import { ClusterAggregationInteractor } from "./application/interactors/ClusterAggregationInteractor";
import { LoginInteractor } from "./application/interactors/LoginInteractor";
import { QuestionCreationInteractor } from "./application/interactors/QuestionCreationInteractor";
// Interactors
import { UserRegistrationInteractor } from "./application/interactors/UserRegistrationInteractor";
import { AuthMiddleware } from "./infrastructure/auth/AuthMiddleware";
import { CloudflareAuthenticationService } from "./infrastructure/auth/CloudflareAuthenticationService";
import { RequestAuthenticationContext } from "./infrastructure/auth/RequestAuthenticationContext";
import { D1AnswerRepository } from "./infrastructure/repositories/D1AnswerRepository";
import { D1BatchRepository } from "./infrastructure/repositories/D1BatchRepository";
import { D1ChoiceRepository } from "./infrastructure/repositories/D1ChoiceRepository";
import { D1ClusterRepository } from "./infrastructure/repositories/D1ClusterRepository";
import { D1QuestionRepository } from "./infrastructure/repositories/D1QuestionRepository";
import { D1UserRepository } from "./infrastructure/repositories/D1UserRepository";

export default {
	async fetch(request: Request, env: Env, _ctx: ExecutionContext) {
		// CORS対応
		if (request.method === "OPTIONS") {
			return new Response(null, {
				status: 200,
				headers: {
					"Access-Control-Allow-Origin": "*",
					"Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
					"Access-Control-Allow-Headers": "Content-Type, Authorization",
				},
			});
		}

		// 認証サービス設定
		const jwtSecret = env.JWT_SECRET || "your-secret-key";
		const authService = new CloudflareAuthenticationService(jwtSecret);
		const authContext = new RequestAuthenticationContext();
		const authMiddleware = new AuthMiddleware(authService, authContext);

		// DI Container setup
		const userRepository = new D1UserRepository(env.DB);
		const answerRepository = new D1AnswerRepository(env.DB);
		const questionRepository = new D1QuestionRepository(env.DB);
		const choiceRepository = new D1ChoiceRepository(env.DB);

		const userRegistrationPresenter = new UserRegistrationPresenter();
		const answerSubmissionPresenter = new AnswerSubmissionPresenter();
		const questionCreationPresenter = new QuestionCreationPresenter();
		const loginPresenter = new LoginPresenter();

		const userRegistrationInteractor = new UserRegistrationInteractor(
			userRepository,
			userRegistrationPresenter,
			authService,
		);
		const answerSubmissionInteractor = new AnswerSubmissionInteractor(
			answerRepository,
			answerSubmissionPresenter,
			authContext,
		);
		const questionCreationInteractor = new QuestionCreationInteractor(
			questionRepository,
			choiceRepository,
			questionCreationPresenter,
		);
		const loginInteractor = new LoginInteractor(
			userRepository,
			loginPresenter,
			authService,
		);

		const userRegistrationController = new UserRegistrationController(
			userRegistrationInteractor,
		);
		const answerSubmissionController = new AnswerSubmissionController(
			answerSubmissionInteractor,
		);
		const questionCreationController = new QuestionCreationController(
			questionCreationInteractor,
		);
		const loginController = new LoginController(loginInteractor);

		// Routing
		const url = new URL(request.url);
		const path = url.pathname;

		// 認証不要のエンドポイント
		if (path === "/signup" && request.method === "POST") {
			return await userRegistrationController.handle(request);
		}

		if (path === "/login" && request.method === "POST") {
			return await loginController.handle(request);
		}

		// 認証が必要なエンドポイント
		const authResult = await authMiddleware.authenticate(request);
		if (!authResult.success) {
			return (
				authResult.response || new Response("Unauthorized", { status: 401 })
			);
		}

		if (path === "/submit" && request.method === "POST") {
			return await answerSubmissionController.handle(request);
		}

		if (path === "/questions" && request.method === "POST") {
			return await questionCreationController.handle(request);
		}

		return new Response("Not Found", { status: 404 });
	},

	async scheduled(
		_controller: ScheduledController,
		env: Env,
		ctx: ExecutionContext,
	) {
		// DI Container setup for scheduled task
		const answerRepository = new D1AnswerRepository(env.DB);
		const clusterRepository = new D1ClusterRepository(env.DB);
		const batchRepository = new D1BatchRepository(env.DB);
		const clusterAggregationPresenter = new ClusterAggregationPresenter();

		const clusterAggregationInteractor = new ClusterAggregationInteractor(
			answerRepository,
			clusterRepository,
			batchRepository,
			clusterAggregationPresenter,
		);

		const clusterAggregationController = new ClusterAggregationController(
			clusterAggregationInteractor,
		);

		ctx.waitUntil(clusterAggregationController.handle());
	},
} satisfies ExportedHandler<Env>;
