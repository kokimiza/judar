export class PasswordHash {
	static async hash(password: string, salt: string): Promise<string> {
		const encoder = new TextEncoder();
		const data = encoder.encode(password + salt);

		const hashBuffer = await crypto.subtle.digest("SHA-256", data);
		const hashArray = new Uint8Array(hashBuffer);

		return Array.from(hashArray)
			.map((b) => b.toString(16).padStart(2, "0"))
			.join("");
	}

	static generateSalt(): string {
		const array = new Uint8Array(32);
		crypto.getRandomValues(array);
		return Array.from(array)
			.map((b) => b.toString(16).padStart(2, "0"))
			.join("");
	}

	static async verify(
		password: string,
		salt: string,
		hash: string,
	): Promise<boolean> {
		const computedHash = await PasswordHash.hash(password, salt);
		return computedHash === hash;
	}
}
