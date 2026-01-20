export class DateId {
	constructor(private readonly value: number) {
		if (value < 10000000 || value > 99999999) {
			throw new Error("DateId must be in YYYYMMDD format");
		}
	}

	static fromDate(date: Date): DateId {
		const value =
			date.getFullYear() * 10000 + (date.getMonth() + 1) * 100 + date.getDate();
		return new DateId(value);
	}

	static today(): DateId {
		return DateId.fromDate(new Date());
	}

	getValue(): number {
		return this.value;
	}
}
