export interface JwtPayload {
	userId: number;
	userName: string;
	iat: number;
	exp: number;
}

export class JwtAuth {
	private secret: string;

	constructor(secret: string) {
		this.secret = secret;
	}

	async generateToken(userId: number, userName: string): Promise<string> {
		const header = {
			alg: "HS256",
			typ: "JWT",
		};

		const payload: JwtPayload = {
			userId,
			userName,
			iat: Math.floor(Date.now() / 1000),
			exp: Math.floor(Date.now() / 1000) + 24 * 60 * 60, // 24時間
		};

		const encodedHeader = this.base64UrlEncode(JSON.stringify(header));
		const encodedPayload = this.base64UrlEncode(JSON.stringify(payload));

		const signature = await this.sign(`${encodedHeader}.${encodedPayload}`);

		return `${encodedHeader}.${encodedPayload}.${signature}`;
	}

	async verifyToken(token: string): Promise<JwtPayload | null> {
		try {
			const parts = token.split(".");
			if (parts.length !== 3) {
				return null;
			}

			const [encodedHeader, encodedPayload, signature] = parts;

			// 署名検証
			const expectedSignature = await this.sign(
				`${encodedHeader}.${encodedPayload}`,
			);
			if (signature !== expectedSignature) {
				return null;
			}

			// ペイロード解析
			const payload: JwtPayload = JSON.parse(
				this.base64UrlDecode(encodedPayload),
			);

			// 有効期限チェック
			if (payload.exp < Math.floor(Date.now() / 1000)) {
				return null;
			}

			return payload;
		} catch {
			return null;
		}
	}

	private async sign(data: string): Promise<string> {
		const encoder = new TextEncoder();
		const key = await crypto.subtle.importKey(
			"raw",
			encoder.encode(this.secret),
			{ name: "HMAC", hash: "SHA-256" },
			false,
			["sign"],
		);

		const signature = await crypto.subtle.sign(
			"HMAC",
			key,
			encoder.encode(data),
		);
		return this.base64UrlEncode(new Uint8Array(signature));
	}

	private base64UrlEncode(data: string | Uint8Array): string {
		const bytes =
			typeof data === "string" ? new TextEncoder().encode(data) : data;
		const base64 = btoa(String.fromCharCode(...bytes));
		return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
	}

	private base64UrlDecode(data: string): string {
		const base64 = data.replace(/-/g, "+").replace(/_/g, "/");
		const padded = base64 + "=".repeat((4 - (base64.length % 4)) % 4);
		return atob(padded);
	}
}
