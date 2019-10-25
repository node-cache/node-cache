import {EventEmitter} from "events";
import {setTimeout, clearTimeout} from "timers";

interface Options {
	forceString: boolean;
	objectValueSize: number;
	promiseValueSize: number;
	arrayValueSize: number;
	stdTTL: number;
	checkperiod: number;
	useClones: boolean;
	deleteOnExpire: boolean;
	enableLegacyCallbacks: boolean;
	maxKeys: number;
}

type ConstructorOptions = Partial<Options>;
type Key = string | number;
interface Box<T> {
	t: number;
	v: T;
}
type ErrorType = keyof typeof Errors;

const ValidKeyTypes = ["string", "number"];

const Errors = {
	ECACHEFULL: () => "Cache max key size exceeded",
	EKEYTYPE: ({type}: {type: string}) =>
		`The key argument has to be of type \`string\` or \`number\`. Found: \`${type}\``,
	EKEYSTYPE: () => "The keys argument has to be an array.",
	ETTLTYPE: () => "The ttl argument has to be a number.",
};

export {NodeCache, ErrorType as NodeCacheErrorType, Key as NodeCacheKey, ConstructorOptions as Options};

export default class NodeCache extends EventEmitter {
	private options: Options;

	private data: {
		[key: string]: Box<any>;
	} = {};

	private stats = {
		hits: 0,
		misses: 0,
		keys: 0,
		ksize: 0,
		vsize: 0,
	};

	private checkTimeout?: NodeJS.Timer;

	constructor(options?: ConstructorOptions) {
		super();

		this.options = Object.assign(
			{
				forceString: false,
				objectValueSize: 80,
				promiseValueSize: 80,
				arrayValueSize: 40,
				stdTTL: 0,
				checkperiod: 600,
				useClones: true,
				deleteOnExpire: true,
				enableLegacyCallbacks: false,
				maxKeys: -1,
			},
			options,
		);

		this.checkData();
	}

	public get = <T = any>(key: Key): T | undefined => {
		this.validateKey(key);

		const wrapped = this.data[key];

		if (wrapped != null && this.check(key, this.data[key])) {
			this.stats.hits++;
			return this.unwrap(wrapped);
		} else {
			this.stats.misses++;
			return;
		}
	};

	public mget = <T extends Key[], U extends any[]>(keys: T): Record<T[number], U[number] | undefined> => {
		if (!Array.isArray(keys)) {
			throw this.createError("EKEYSTYPE");
		}

		const record: Record<Key, U[number] | undefined> = {};

		for (let i = 0; i < keys.length; i++) {
			const key = keys[i];

			this.validateKey(key);

			const wrapped = this.data[key];
			if (wrapped != null && this.check(key, wrapped)) {
				this.stats.hits++;
				record[key] = this.unwrap<U[number]>(wrapped);
			}
		}

		return record;
	};

	public set = <T = any>(key: Key, value: T, ttl?: number): boolean => {
		if (this.options.maxKeys > -1 && this.stats.keys >= this.options.maxKeys) {
			throw this.createError("ECACHEFULL");
		}

		if (this.options.forceString && typeof value !== "string") {
			(value as any) = JSON.stringify(value);
		}

		if (ttl == null) {
			ttl = this.options.stdTTL;
		}

		this.validateKey(key);

		let isExistingKey = false;

		const wrapped = this.data[key];

		if (wrapped) {
			isExistingKey = true;
			this.stats.vsize -= this.getValLength(this.unwrap(wrapped, false));
		}

		this.data[key] = this.wrap(value, ttl);
		this.stats.vsize += this.getValLength(value);

		if (!isExistingKey) {
			this.stats.ksize += this.getKeyLength(key);
			this.stats.keys++;
		}

		this.emit("set", key, value);
		return true;
	};

	public mset = (keyValueSet: {key: Key; val: any; ttl?: number}[]): true => {
		if (this.options.maxKeys > -1 && this.stats.keys + keyValueSet.length >= this.options.maxKeys) {
			throw this.createError("ECACHEFULL");
		}

		for (let i = 0; i < keyValueSet.length; i++) {
			const {key, ttl} = keyValueSet[i];

			if (ttl && typeof ttl !== "number") {
				throw this.createError("ETTLTYPE");
			}

			this.validateKey(key);
		}

		for (let i = 0; i < keyValueSet.length; i++) {
			const {key, val, ttl} = keyValueSet[i];
			this.set(key, val, ttl);
		}

		return true;
	};

	public del = (keys: Key | Key[]) => {
		if (!Array.isArray(keys)) {
			keys = [keys];
		}

		let counter = 0;
		for (let i = 0; i < keys.length; i++) {
			const key = keys[i];

			this.validateKey(key);

			const wrapped = this.data[key];
			if (wrapped != null) {
				this.stats.vsize -= this.getValLength(this.unwrap(wrapped, false));
				this.stats.ksize -= this.getKeyLength(key);
				this.stats.keys--;
				counter++;

				delete this.data[key];
				this.emit("del", key, wrapped.v);
			}
		}

		return counter;
	};

	public ttl = (key: Key, ttl?: number): boolean => {
		if (ttl == null) {
			ttl = this.options.stdTTL;
		}

		this.validateKey(key);

		const wrapped = this.data[key];
		if (wrapped != null && this.check(key, wrapped)) {
			if (ttl >= 0) {
				this.data[key] = this.wrap(wrapped.v, ttl, false);
			} else {
				this.del(key);
			}
			return true;
		} else {
			return false;
		}
	};

	public getTtl = (key: Key) => {
		this.validateKey(key);

		const wrapped = this.data[key];
		if (wrapped != null && this.check(key, wrapped)) {
			return wrapped.t;
		} else {
			return;
		}
	};

	public keys = () => Object.keys(this.data);

	public has = (key: Key) => {
		const wrapped = this.data[key];
		return wrapped != null && this.check(key, wrapped);
	};

	public getStats = () => this.stats;

	public flushAll = (startPeriod = true) => {
		this.data = {};
		this.stats = {
			hits: 0,
			misses: 0,
			keys: 0,
			ksize: 0,
			vsize: 0,
		};
		this.killCheckPeriod();
		this.checkData(startPeriod);
		this.emit("flush");
	};

	public close = () => {
		this.killCheckPeriod();
	};

	private wrap = <T = any>(value: T, ttl: number, asClone = true): Box<T> => {
		if (!this.options.useClones) {
			asClone = false;
		}

		const now = Date.now();
		let lifetime = 0;
		const ttlMultiplicator = 1000;
		if (ttl === 0) {
			lifetime = 0;
		} else if (ttl) {
			lifetime = now + ttl * ttlMultiplicator;
		} else if (this.options.stdTTL) {
			lifetime = this.options.stdTTL === 0 ? 0 : now + this.options.stdTTL * ttlMultiplicator;
		}

		return {
			t: lifetime,
			v: asClone ? clone(value) : value,
		};
	};

	private unwrap = <T = any>(wrapped: Box<T>, asClone = true): T | null => {
		if (!this.options.useClones) {
			asClone = false;
		}

		if (wrapped.v == null) {
			return null;
		}

		return asClone ? clone(wrapped.v) : wrapped.v;
	};

	private check = (key: Key, wrapped: Box<any>): boolean => {
		if (wrapped.t !== 0 && wrapped.t < Date.now()) {
			if (this.options.deleteOnExpire) {
				this.del(key);
			}
			this.emit("expired", key, this.unwrap(wrapped));
			return false;
		} else {
			return true;
		}
	};

	private checkData = (startPeriod = true) => {
		for (let key in this.data) {
			this.check(key, this.data[key]);
		}

		if (startPeriod && this.options.checkperiod > 0) {
			this.checkTimeout = (setTimeout(
				this.checkData,
				this.options.checkperiod * 1000,
			) as unknown) as NodeJS.Timer;
			this.checkTimeout.unref();
		}
	};

	private killCheckPeriod = () => {
		if (this.checkTimeout != null) {
			clearTimeout(this.checkTimeout);
		}
	};

	private getKeyLength = (key: Key) => key.toString().length;
	private getValLength = (value: any) => {
		const type = typeof value;

		if (type === "string") {
			return value.length;
		} else if (this.options.forceString) {
			return JSON.stringify(value).length;
		} else if (Array.isArray(value)) {
			return this.options.arrayValueSize * value.length;
		} else if (value === "number") {
			return 8;
		} else if (value && typeof value.then === "function") {
			return this.options.promiseValueSize;
		} else if (type === "object") {
			return this.options.objectValueSize * Object.keys(value).length;
		} else if (type === "boolean") {
			return 8;
		} else {
			return 0;
		}
	};

	private validateKey = (key: Key) => {
		const type = typeof key;
		if (!ValidKeyTypes.includes(type)) {
			throw this.createError("EKEYTYPE", {
				type,
			});
		}
	};

	private createError = (type: ErrorType, data?: any) => {
		const error = new Error();
		error.name = type;
		(error as any).errorcode = type;
		error.message = (Errors as any)[type] != null ? (Errors as any)[type](data) : "-";
		(error as any).data = data;
		return error;
	};
}
