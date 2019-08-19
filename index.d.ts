// Type definitions for node-cache 4.1
// Project: https://github.com/tcs-de/nodecache
// Definitions by: Ilya Mochalov <https://github.com/chrootsu>
//                 Daniel Thunell <https://github.com/dthunell>
//                 Ulf Seltmann <https://github.com/useltmann>
// Definitions: https://github.com/DefinitelyTyped/DefinitelyTyped

/// <reference types="node" />

/**
 * Since 4.1.0: Key-validation: The keys can be given as either string or number,
 * but are casted to a string internally anyway.
 */
type Key = string | number;

declare namespace NodeCache {
	interface NodeCache {
		/** container for cached data */
		data: Data;

		/** module options */
		options: Options;

		/** statistics container */
		stats: Stats;

		/**
		 * get a cached key and change the stats
		 *
		 * @param key cache key or an array of keys
		 */
		get<T>(key: Key): T | undefined;

		/**
		 * get multiple cached keys at once and change the stats
		 *
		 * @param keys an array of keys
		 */
		mget<T>(keys: Key[]): { [key: string]: T };

		/**
		 * set a cached key and change the stats
		 *
		 * @param key cache key
		 * @param value A element to cache. If the option `option.forceString` is `true` the module trys to translate
		 * it to a serialized JSON
		 * @param ttl The time to live in seconds.
		 */
		set<T>(key: Key, value: T, ttl: number | string): boolean;

		set<T>(key: Key, value: T): boolean;

		/**
		 * remove keys
		 * @param keys cache key to delete or a array of cache keys
		 * @returns Number of deleted keys
		 */
		del(keys: Key | Key[]): number;

		/**
		 * reset or redefine the ttl of a key. If `ttl` is not passed or set to 0 it's similar to `.del()`
		 */
		ttl(key: Key, ttl: number): boolean;

		ttl(key: Key): boolean;

		getTtl(key: Key): number | undefined;

		/**
		 * list all keys within this cache
		 * @returns An array of all keys
		 */
		keys(): string[];

		/**
		 * get the stats
		 *
		 * @returns Stats data
		 */
		getStats(): Stats;

		/**
		 * flush the whole data and reset the stats
		 */
		flushAll(): void;

		/**
		 * This will clear the interval timeout which is set on checkperiod option.
		 */
		close(): void;
	}

	interface Data {
		[key: string]: WrappedValue<any>;
	}

	interface Options {
		forceString?: boolean;
		objectValueSize?: number;
		arrayValueSize?: number;
		stdTTL?: number;
		checkperiod?: number;
		useClones?: boolean;
		errorOnMissing?: boolean;
		deleteOnExpire?: boolean;
	}

	interface Stats {
		hits: number;
		misses: number;
		keys: number;
		ksize: number;
		vsize: number;
	}

	interface WrappedValue<T> {
		// ttl
		t: number;
		// value
		v: T;
	}

	type Callback<T> = (err: any, data: T | undefined) => void;
}

import events = require("events");

import Data = NodeCache.Data;
import Options = NodeCache.Options;
import Stats = NodeCache.Stats;
import Callback = NodeCache.Callback;

declare class NodeCache extends events.EventEmitter
	implements NodeCache.NodeCache {
	/** container for cached data */
	data: Data;

	/** module options */
	options: Options;

	/** statistics container */
	stats: Stats;

	constructor(options?: Options);

	/**
	 * get a cached key and change the stats
	 *
	 * @param key cache key or an array of keys
	 */
	get<T>(key: Key): T | undefined;

	/**
	 * get multiple cached keys at once and change the stats
	 *
	 * @param keys an array of keys
	 */
	mget<T>(keys: Key[]): { [key: string]: T };

	/**
	 * set a cached key and change the stats
	 *
	 * @param key cache key
	 * @param value A element to cache. If the option `option.forceString` is `true` the module trys to translate
	 * it to a serialized JSON
	 * @param ttl The time to live in seconds.
	 */
	set<T>(key: Key, value: T, ttl: number | string): boolean;

	set<T>(key: Key, value: T): boolean;

	/**
	 * remove keys
	 * @param keys cache key to delete or a array of cache keys
	 * @param cb Callback function
	 * @returns Number of deleted keys
	 */
	del(keys: Key | Key[]): number;

	/**
	 * reset or redefine the ttl of a key. If `ttl` is not passed or set to 0 `stdTtl` is used. if set lt 0 it's similar to `.del()`
	 */
	ttl(key: Key, ttl: number): boolean;

	ttl(key: Key): boolean;

	getTtl(key: Key): number | undefined;

	/**
	 * list all keys within this cache
	 * @returns An array of all keys
	 */
	keys(): string[];

	/**
	 * Check if a key is cached
	 * @param key cache key to check
	 * @returns Boolean indicating if the key is cached or not
	 */
	has(key: Key): boolean;

	/**
	 * get the stats
	 *
	 * @returns Stats data
	 */
	getStats(): Stats;

	/**
	 * flush the hole data and reset the stats
	 */
	flushAll(): void;

	/**
	 * This will clear the interval timeout which is set on checkperiod option.
	 */
	close(): void;
}

export = NodeCache;
