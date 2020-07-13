/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS202: Simplify dynamic range loops
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */

import clone from "clone";

const pkg = require("../package.json");

import nodeCache from "../src/index";
const {randomString, randomNumber, diffKeys} = require("./helpers");

const localCache = new nodeCache({
	stdTTL: 0,
});

const localCacheNoClone = new nodeCache({
	stdTTL: 0,
	useClones: false,
	checkperiod: 0,
});

const localCacheMaxKeys = new nodeCache({
	maxKeys: 2,
});

const localCacheTTL = new nodeCache({
	stdTTL: 0.3,
	checkperiod: 0,
});

const localCacheNoDelete = new nodeCache({
	stdTTL: 0.3,
	checkperiod: 0,
	deleteOnExpire: false,
});

const localCacheMset = new nodeCache({
	stdTTL: 0,
});

const BENCH: any = {};

// store test state
let state: any = {};

describe(`\`${pkg.name}@${pkg.version}\` on \`node@${process.version}\``, function() {
	afterAll(function() {
		let txt = `Benchmark node@${process.version}:`;
		for (let type in BENCH) {
			const ops = BENCH[type];
			txt += `\n   - ${type}: ${ops.toFixed(1)} ops/s`;
		}
		console.log(txt);
	});

	describe("general sync-style", function() {
		beforeAll(function() {
			localCache.flushAll();

			state = {
				start: clone(localCache.getStats()),
				value: randomString(100),
				value2: randomString(100),
				value3: randomString(100),
				key: randomString(10),
				obj: {
					a: 1,
					b: {
						x: 2,
						y: 3,
					},
				},
			};
		});

		it("set key", function() {
			const res = localCache.set(state.key, state.value, 0);
			expect(res).toBe(true);
			expect(localCache.getStats().keys - state.start.keys).toBe(1);
		});

		it("get key", function() {
			const res = localCache.get(state.key);
			expect(state.value).toBe(res);
		});

		it("get key names", function() {
			const res = localCache.keys();
			expect([state.key]).toStrictEqual(res);
		});

		it("has key", function() {
			const res = localCache.has(state.key);
			expect(res).toBe(true);
		});

		it("does not have key", function() {
			const res = localCache.has("non existing key");
			expect(res).toBe(false);
		});

		it("delete an undefined key", function() {
			const count = localCache.del("xxx");
			expect(0).toBe(count);
		});

		it("update key (and get it to check if the update worked)", function() {
			let res: any = localCache.set(state.key, state.value2, 0);
			expect(true).toBe(res);

			// check if the update worked
			res = localCache.get(state.key);
			expect(state.value2).toBe(res);

			// stats should not have changed
			expect(1).toBe(localCache.getStats().keys - state.start.keys);
		});

		it("delete the defined key", function() {
			localCache.once("del", function(key: string, val: any) {
				expect(state.key).toBe(key);
				expect(state.value2).toBe(val);
			});
			const count = localCache.del(state.key);
			expect(1).toBe(count);

			// check stats
			expect(0).toBe(localCache.getStats().keys - state.start.keys);
		});

		it("delete multiple keys (after setting them)", function() {
			const keys = ["multiA", "multiB", "multiC"];
			// set the keys
			keys.forEach(function(key) {
				const res = localCache.set(key, state.value3);
				expect(true).toBe(res);
			});
			// check the keys
			keys.forEach(function(key) {
				const res = localCache.get(key);
				expect(state.value3).toBe(res);
			});
			// delete 2 of those keys
			let count = localCache.del(keys.slice(0, 2));
			expect(2).toBe(count);
			// try to get the deleted keys
			keys.slice(0, 2).forEach(function(key) {
				const res = localCache.get(key);
				expect(res).toBe(undefined);
			});
			// get the not deleted key
			let res = localCache.get(keys[2]);
			expect(state.value3).toBe(res);
			// delete this key, too
			count = localCache.del(keys[2]);
			expect(1).toBe(count);
			// try get the deleted key
			res = localCache.get(keys[2]);
			expect(res).toBe(undefined);
			// re-deleting the keys should not have to delete an actual key
			count = localCache.del(keys);
			expect(0).toBe(count);
		});

		it("set a key to 0", function() {
			const res = localCache.set("zero", 0);
			expect(true).toBe(res);
		});

		it("get previously set key", function() {
			const res = localCache.get("zero");
			expect(0).toBe(res);
		});

		it("set a key to an object clone", function() {
			const res = localCache.set("clone", state.obj);
			expect(true).toBe(res);
		});

		it("get cloned object", function() {
			const res = localCache.get("clone");

			res.b.y = 42;
			const res2 = localCache.get("clone");
			expect(state.obj).toStrictEqual(res2);
		});

		it("test promise storage (fulfill before adding to cache)", function(done) {
			const deferred_value = "Some deferred value";
			if (typeof Promise !== "undefined" && Promise !== null) {
				const p = new Promise(function(fulfill) {
					fulfill(deferred_value);
				});
				p.then(function(value) {
					expect(deferred_value).toBe(value);
				});
				localCache.set("promise", p);
				const q = localCache.get("promise");
				q.then(function() {
					done();
				});
			} else {
				if (process.env.SILENT_MODE == null) {
					console.log(`No Promises available in this node version (${process.version})`);
				}
				done();
			}
		});

		it("test promise storage (fulfill after adding to cache)", function(done) {
			const deferred_value = "Some deferred value";
			if (typeof Promise !== "undefined" && Promise !== null) {
				let called = 0;
				const callStub = function() {
					called++;
					if (called === 2) {
						done();
					}
				};

				const p = new Promise(function(fulfill) {
					const fulfiller = function() {
						fulfill(deferred_value);
					};
					setTimeout(fulfiller, 250);
				});
				p.then(function(value) {
					expect(deferred_value).toBe(value);
					callStub();
				});
				localCache.set("promise", p);
				const q = localCache.get("promise");
				q.then(function(value: any) {
					expect(deferred_value).toBe(value);
					callStub();
				});
			} else {
				if (process.env.SILENT_MODE == null) {
					console.log(`No Promises available in this node version (${process.version})`);
				}
				done();
			}
		});

		it("test es6 map", function(done) {
			if (typeof Map === "undefined" || Map === null) {
				if (process.env.SILENT_MODE == null) {
					console.log(`No Maps available in this node version (${process.version})`);
				}
				done();
				return;
			}

			const key = randomString(10);
			const map = new Map([
				["firstkey", "firstvalue"],
				["2ndkey", "2ndvalue"],
				["thirdkey", "thirdvalue"],
			]);

			localCache.set(key, map);

			map.set("fourthkey", "fourthvalue");

			const cached_map = localCache.get(key);
			expect(cached_map.get("2ndkey")).toBe("2ndvalue");
			expect(cached_map.get("fourthkey")).toBe(undefined);
			done();
		});

		it("test `useClones = true` with an Object", function() {
			const key = randomString(10);
			const value = {
				a: 123,
				b: 456,
			};
			const c = 789;

			localCache.set(key, value);
			value.a = c;

			expect(value).not.toEqual(localCache.get(key));
		});

		it("test `useClones = false` with an Object", function() {
			const key = randomString(10);
			const value = {
				a: 123,
				b: 456,
			};
			const c = 789;

			localCacheNoClone.set(key, value);
			value.a = c;

			expect(value === localCacheNoClone.get(key)).toBe(true);
		});
	});

	describe("max key amount", function() {
		beforeAll(function() {
			state = {
				key1: randomString(10),
				key2: randomString(10),
				key3: randomString(10),
				value1: randomString(10),
				value2: randomString(10),
				value3: randomString(10),
			};
		});

		it("exceed max key size", function() {
			const setKey = localCacheMaxKeys.set(state.key1, state.value1, 0);
			expect(true).toBe(setKey);

			const setKey2 = localCacheMaxKeys.set(state.key2, state.value2, 0);
			expect(true).toBe(setKey2);

			expect(() => localCacheMaxKeys.set(state.key3, state.value3, 0)).toThrow();
		});

		it("remove a key and set another one", function() {
			const del = localCacheMaxKeys.del(state.key1);
			expect(1).toBe(del);

			const setKey3 = localCacheMaxKeys.set(state.key3, state.value3, 0);
			expect(true).toBe(setKey3);
		});
	});

	describe("correct and incorrect key types", function() {
		describe("number", function() {
			beforeAll(function() {
				state = {
					keys: [],
					val: randomString(20),
				};

				for (let i = 1; i <= 10; i++) {
					state.keys.push(randomNumber(100000));
				}
			});

			it("set", function() {
				for (let key of Array.from(state.keys) as string[]) {
					const res = localCache.set(key, state.val);
					expect(true).toBe(res);
				}
			});

			it("get", function() {
				const res = localCache.get(state.keys[0]);
				expect(state.val).toBe(res);
			});

			it("mget", function() {
				const res = localCache.mget(state.keys.slice(0, 2));
				// generate prediction
				const prediction: any = {};
				prediction[state.keys[0]] = state.val;
				prediction[state.keys[1]] = state.val;
				expect(prediction).toStrictEqual(res);
			});

			it("del single", function() {
				const count = localCache.del(state.keys[0]);
				expect(1).toBe(count);
			});

			it("del multi", function() {
				const count = localCache.del(state.keys.slice(1, 3));
				expect(2).toBe(count);
			});

			it("ttl", function(done) {
				const success = localCache.ttl(state.keys[3], 0.3);
				expect(true).toBe(success);

				let res = localCache.get(state.keys[3]);
				expect(state.val).toBe(res);

				setTimeout(function() {
					res = localCache.get(state.keys[3]);
					expect(res).toBe(undefined);
					done();
				}, 400);
			});

			it("getTtl", function() {
				let middle;
				const now = Date.now();
				const success = localCache.ttl(state.keys[4], 0.5);
				expect(true).toBe(success);

				const ttl: any = localCache.getTtl(state.keys[4]);
				expect(485 < (middle = ttl - now) && middle < 510).toBe(true);
			});

			afterAll(function() {
				localCache.flushAll(false);
			});
		});

		describe("string", function() {
			beforeAll(function() {
				state = {
					keys: [],
					val: randomString(20),
				};

				for (let i = 1; i <= 10; i++) {
					state.keys.push(randomString(10));
				}
			});

			it("set", function() {
				for (let key of Array.from(state.keys) as string[]) {
					const res = localCache.set(key as string, state.val);
					expect(true).toBe(res);
				}
			});

			it("get", function() {
				const res = localCache.get(state.keys[0]);
				expect(state.val).toBe(res);
			});

			it("mget", function() {
				const res = localCache.mget(state.keys.slice(0, 2));
				// generate prediction
				const prediction: any = {};
				prediction[state.keys[0]] = state.val;
				prediction[state.keys[1]] = state.val;
				expect(prediction).toStrictEqual(res);
			});

			it("del single", function() {
				const count = localCache.del(state.keys[0]);
				expect(1).toBe(count);
			});

			it("del multi", function() {
				const count = localCache.del(state.keys.slice(1, 3));
				expect(2).toBe(count);
			});

			it("ttl", function(done) {
				const success = localCache.ttl(state.keys[3], 0.3);
				expect(true).toBe(success);

				let res = localCache.get(state.keys[3]);
				expect(state.val).toBe(res);

				setTimeout(function() {
					res = localCache.get(state.keys[3]);
					expect(res).toBe(undefined);
					done();
				}, 400);
			});

			it("getTtl", function() {
				let middle;
				const now = Date.now();
				const success = localCache.ttl(state.keys[4], 0.5);
				expect(true).toBe(success);

				const ttl: any = localCache.getTtl(state.keys[4]);
				expect(485 < (middle = ttl - now) && middle < 510).toBe(true);
			});
		});

		describe("boolean - invalid type", function() {
			beforeAll(function() {
				state = {
					keys: [true, false],
					val: randomString(20),
				};
			});

			it("set sync-style", function() {
				expect(() => localCache.set(state.keys[0], state.val)).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`",
				});
			});

			it("get sync-style", function() {
				expect(() => localCache.get(state.keys[0])).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`",
				});
			});

			it("mget sync-style", function() {
				expect(() => localCache.mget(state.keys)).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`",
				});
			});

			it("del single sync-style", function() {
				expect(() => localCache.del(state.keys[0])).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`",
				});
			});

			it("del multi sync-style", function() {
				expect(() => localCache.del(state.keys)).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`",
				});
			});

			it("ttl sync-style", function() {
				expect(() => localCache.ttl(state.keys[0], 10)).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`",
				});
			});

			it("getTtl sync-style", function() {
				expect(() => localCache.getTtl(state.keys[0])).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`",
				});
			});
		});

		describe("object - invalid type", function() {
			beforeAll(function() {
				state = {
					keys: [{a: 1}, {b: 2}],
					val: randomString(20),
				};
			});

			it("set sync-style", function() {
				expect(() => localCache.set(state.keys[0], state.val)).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `object`",
				});
			});

			it("get sync-style", function() {
				expect(() => localCache.get(state.keys[0])).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `object`",
				});
			});

			it("mget sync-style", function() {
				expect(() => localCache.mget(state.keys)).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `object`",
				});
			});

			it("del single sync-style", function() {
				expect(() => localCache.del(state.keys[0])).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `object`",
				});
			});

			it("del multi sync-style", function() {
				expect(() => localCache.del(state.keys)).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `object`",
				});
			});

			it("ttl sync-style", function() {
				expect(() => localCache.ttl(state.keys[0], 10)).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `object`",
				});
			});

			it("getTtl sync-style", function() {
				expect(() => localCache.getTtl(state.keys[0])).toThrow({
					name: "EKEYTYPE",
					message: "The key argument has to be of type `string` or `number`. Found: `object`",
				});
			});
		});
	});

	describe("flush", function() {
		beforeAll(function() {
			state = {
				n: 0,
				count: 100,
				startKeys: localCache.getStats().keys,
				keys: [],
				val: randomString(20),
			};
		});

		it("set keys", function() {
			for (let i = 1, end = state.count, asc = 1 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
				const key = randomString(7);
				state.keys.push(key);
			}

			state.keys.forEach(function(key: string) {
				localCache.set(key, "");
				state.n++;
			});

			expect(state.count).toBe(state.n);
			expect(state.startKeys + state.count).toBe(localCache.getStats().keys);
		});

		it("flush keys", function() {
			localCache.flushAll(false);

			expect(0).toBe(localCache.getStats().keys);
		});
	});

	describe("many", () =>
		beforeAll(function() {
			state = {
				n: 0,
				count: 100000,
				keys: [],
				val: randomString(20),
			};

			for (let i = 1, end = state.count, asc = 1 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
				const key = randomString(7);
				state.keys.push(key);
			}
		}));

	describe("delete", function() {
		beforeAll(function() {
			// don't override state because we still need `state.keys`
			state.n = 0;
		});

		beforeAll(function() {
			state = {
				n: 0,
				count: 100000,
				keys: [],
				val: randomString(20),
			};

			for (let i = 1, end = state.count, asc = 1 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
				const key = randomString(7);
				state.keys.push(key);
				localCache.set(key, state.val);
			}
		});

		it("delete all previously set keys", function() {
			for (let i = 0, end = state.count, asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
				expect(1).toBe(localCache.del(state.keys[i]));
				state.n++;
			}

			expect(state.n).toBe(state.count);
			expect(localCache.getStats().keys).toBe(0);
		});

		it("delete keys again; should not delete anything", function() {
			for (let i = 0, end = state.count, asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
				expect(0).toBe(localCache.del(state.keys[i]));
				state.n++;
			}

			expect(state.n).toBe(state.count * 2);
			expect(localCache.getStats().keys).toBe(0);
		});
	});

	describe("stats", function() {
		beforeAll(function() {
			state = {
				n: 0,
				start: clone(localCache.getStats()),
				count: 5,
				keylength: 7,
				valuelength: 50,
				keys: [],
				values: [],
			};

			for (let i = 1, end = state.count * 2, asc = 1 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
				const key = randomString(state.keylength);
				const value = randomString(state.valuelength);
				state.keys.push(key);
				state.values.push(value);

				expect(true).toBe(localCache.set(key, value, 0));
				state.n++;
			}
		});

		it("get and remove `count` elements", function() {
			let i;
			let asc, end;
			let asc1, end1;
			for (i = 1, end = state.count, asc = 1 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
				expect(state.values[i]).toBe(localCache.get(state.keys[i]));
				state.n++;
			}

			for (i = 1, end1 = state.count, asc1 = 1 <= end1; asc1 ? i <= end1 : i >= end1; asc1 ? i++ : i--) {
				expect(1).toBe(localCache.del(state.keys[i]));
				state.n++;
			}

			const after = localCache.getStats();
			const diff = diffKeys(after, state.start);

			expect(diff.hits).toBe(5);
			expect(diff.keys).toBe(5);
			expect(diff.ksize).toBe(state.count * state.keylength);
			expect(diff.vsize).toBe(state.count * state.valuelength);
		});

		it("generate `count` misses", function() {
			for (let i = 1, end = state.count, asc = 1 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
				// 4 char key should not exist
				expect(localCache.get("xxxx")).toBe(undefined);
				state.n++;
			}

			const after = localCache.getStats();
			const diff = diffKeys(after, state.start);

			expect(diff.misses).toBe(5);
		});

		it("check successful runs", function() {
			expect(state.n).toBe(5 * state.count);
		});
	});

	describe("multi", function() {
		beforeAll(function() {
			let key;
			state = {
				n: 0,
				count: 100,
				startKeys: localCache.getStats().keys,
				value: randomString(20),
				keys: [],
			};

			for (let i = 1, end = state.count, asc = 1 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
				key = randomString(7);
				state.keys.push(key);
			}

			for (key of Array.from(state.keys) as string[]) {
				localCache.set(key, state.value, 0);
				state.n++;
			}
		});

		it("generate a sub-list of keys", function() {
			state.getKeys = state.keys.splice(50, 5);
		});

		it("generate prediction", function() {
			state.prediction = {};
			for (let key of Array.from(state.getKeys) as string[]) {
				state.prediction[key] = state.value;
			}
		});

		it("try to mget with a single key", function() {
			expect(() => localCache.mget(state.getKeys[0])).toThrow({
				name: "EKEYSTYPE",
				message: "The keys argument has to be an array.",
			});
			state.n++;
		});

		it("mget the sub-list", function() {
			expect(state.prediction).toStrictEqual(localCache.mget(state.getKeys));
			state.n++;
		});

		it("delete keys in the sub-list", function() {
			expect(state.getKeys.length).toBe(localCache.del(state.getKeys));
			state.n++;
		});

		it("try to mget the sub-list again", function() {
			expect({}).toStrictEqual(localCache.mget(state.getKeys));
			state.n++;
		});

		it("check successful runs", function() {
			expect(state.n).toBe(state.count + 4);
		});
	});

	describe("ttl", function() {
		beforeAll(function() {
			state = {
				n: 0,
				val: randomString(20),
				key1: `k1_${randomString(20)}`,
				key2: `k2_${randomString(20)}`,
				key3: `k3_${randomString(20)}`,
				key4: `k4_${randomString(20)}`,
				key5: `k5_${randomString(20)}`,
				key6: `k6_${randomString(20)}`,
				now: Date.now(),
			};
			state.keys = [state.key1, state.key2, state.key3, state.key4, state.key5];
		});

		describe("has validates expired ttl", function() {
			it("set a key with ttl", function() {
				expect(true).toBe(localCacheTTL.set(state.key6, state.val, 0.7));
			});

			it("check this key immediately", function() {
				expect(true).toBe(localCacheTTL.has(state.key6));
			});

			it("before it times out", function(done) {
				setTimeout(function() {
					state.n++;
					const res = localCacheTTL.has(state.key6);
					expect(res).toBe(true);
					expect(state.val).toBe(localCacheTTL.get(state.key6));
					done();
				}, 20);
			});

			it("and after it timed out", function(done) {
				setTimeout(function() {
					const res = localCacheTTL.has(state.key6);
					expect(res).toBe(false);

					state.n++;
					expect(localCacheTTL.get(state.key6)).toBe(undefined);
					done();
				}, 800);
			});
		});

		it("set a key with ttl", function() {
			const res = localCache.set(state.key1, state.val, 0.7);
			expect(true).toBe(res);
			const ts = localCache.getTtl(state.key1) as number;
			if (state.now < ts && ts < state.now + 300) {
				throw new Error("Invalid timestamp");
			}
		});

		it("check this key immediately", function() {
			expect(state.val).toBe(localCache.get(state.key1));
		});

		it("before it times out", function(done) {
			setTimeout(function() {
				state.n++;
				const res = localCache.has(state.key1);
				expect(res).toBe(true);
				expect(state.val).toBe(localCache.get(state.key1));
				done();
			}, 20);
		});

		it("and after it timed out", function(done) {
			setTimeout(function() {
				const res = localCache.has(state.key1);
				expect(res).toBe(false);

				const ts = localCache.getTtl(state.key1);
				expect(ts).toBe(undefined);

				state.n++;
				expect(localCache.get(state.key1)).toBe(undefined);
				done();
			}, 700);
		});

		it("set another key with ttl", function() {
			const res = localCache.set(state.key2, state.val, 0.5);
			expect(true).toBe(res);
		});

		it("check this key immediately", function() {
			const res = localCache.get(state.key2);
			expect(state.val).toBe(res);
		});

		it("before it times out", function(done) {
			setTimeout(function() {
				state.n++;

				expect(state.val).toBe(localCache.get(state.key2));
				done();
			}, 20);
		});

		it("and after it timed out, too", function(done) {
			setTimeout(function() {
				const ts = localCache.getTtl(state.key2);
				expect(ts).toBe(undefined);

				state.n++;
				expect(localCache.get(state.key2)).toBe(undefined);
				done();
			}, 500);
		});

		describe("test the automatic check", function() {
			let innerState: {
				cache: nodeCache;
				key: string;
				val: string;
			};

			beforeAll(function() {
				const innerStateCache = new nodeCache();

				innerState = {
					cache: innerStateCache,
					key: "autotest",
					val: randomString(20),
				};
			});

			it("set a key with ttl", function() {
				innerState.cache.once("set", function(key) {
					expect(innerState.key).toBe(key);
				});

				expect(innerState.cache.set(innerState.key, innerState.val, 0.5)).toBe(true);

				expect(1).toBe(innerState.cache.getStats().keys);

				// event handler should have been fired
				expect(0).toBe(innerState.cache.listeners("set").length);
			});

			it("and check it's existence", function() {
				expect(innerState.cache.get(innerState.key)).toBe(innerState.val);
			});

			it("wait for 'expired' event", function(done) {
				innerState.cache.on("expired", function(key) {
					expect(key).toBe(innerState.key);
					expect(!Array.from(state.keys).includes(key)).toBe(true);
					done();
				});

				setTimeout(() => {
					// trigger ttl check, which will trigger the `expired` event
					innerState.cache.get(innerState.key);
				}, 550);
			});
		});

		describe("more ttl tests", function() {
			it("set a third key with ttl", function() {
				expect(true).toBe(localCache.set(state.key3, state.val, 100));
			});

			it("check it immediately", function() {
				expect(state.val).toBe(localCache.get(state.key3));
			});

			it("set ttl to the invalid key", function() {
				expect(false).toBe(localCache.ttl(`${state.key3}false`, 0.3));
			});

			it("set ttl to the correct key", function() {
				expect(true).toBe(localCache.ttl(state.key3, 0.3));
			});

			it("check if the key still exists", function() {
				const res = localCache.get(state.key3);
				expect(state.val).toBe(res);
			});

			it("wait until ttl has ended and check if the key was deleted", function(done) {
				setTimeout(function() {
					const res = localCache.get(state.key3);
					expect(res).toBe(undefined);
					done();
				}, 500);
			});

			it("set a key with ttl = 100s (default: infinite), reset it's ttl to default and check if it still exists", function() {
				expect(true).toBe(localCache.set(state.key4, state.val, 100));

				// check immediately
				expect(state.val).toBe(localCache.get(state.key4));

				// set ttl to false key
				expect(false).toBe(localCache.ttl(`${state.key4}false`));

				// set default ttl (0) to the right key
				expect(true).toBe(localCache.ttl(state.key4));

				// and check if it still exists
				const res = localCache.get(state.key4);
				expect(state.val).toBe(res);
			});

			it("set a key with ttl = 100s (default: 0.3s), reset it's ttl to default, check if it still exists, and wait for its timeout", function(done) {
				expect(true).toBe(localCacheTTL.set(state.key5, state.val, 100));

				// check immediately
				expect(state.val).toBe(localCacheTTL.get(state.key5));

				// set ttl to false key
				expect(false).toBe(localCacheTTL.ttl(`${state.key5}false`));

				// set default ttl (0.3) to right key
				expect(true).toBe(localCacheTTL.ttl(state.key5));

				// and check if it still exists
				expect(state.val).toBe(localCacheTTL.get(state.key5));

				setTimeout(function() {
					const res = localCacheTTL.get(state.key5);
					expect(res).toBe(undefined);

					done();
				}, 350);
			});

			it("set a key key with a cache initialized with no automatic delete on expire should be undefined", function(done) {
				localCacheNoDelete.set(state.key1, state.val);
				setTimeout(function() {
					const res = localCacheNoDelete.get(state.key1);
					expect(res).toBe(undefined);
					done();
				}, 500);
			});

			it("test issue #78 with expire event not fired", function(done) {
				const localCacheTTL2 = new nodeCache({
					stdTTL: 1,
					checkperiod: 0.5,
				});
				let expCount = 0;
				const expkeys = ["ext78_test:a", "ext78_test:b"];

				localCacheTTL2.on("expired", function(key, value) {
					expect(key).toBe(expkeys[expCount]);
					expect(value).toBe(expkeys[expCount]);
					expCount++;
				});

				localCacheTTL2.set(expkeys[0], expkeys[0], 0.5);
				localCacheTTL2.set(expkeys[1], expkeys[1], 1);

				setTimeout(function() {
					expect(expCount).toBe(2);
					localCacheTTL2.close();
					done();
				}, 2000);
			});
		});
	});

	describe("clone", function() {
		it("a function", function(done) {
			const key = randomString(10);

			const value = function() {
				done();
			};

			localCache.set(key, value);

			const fn = localCache.get(key);
			fn();
		});

		it("a regex", function() {
			const key = randomString(10);
			const regex = new RegExp("\\b\\w{4}\\b", "g");
			const match = "king";
			const noMatch = "bla";

			expect(true).toBe(regex.test(match));
			expect(false).toBe(regex.test(noMatch));

			localCache.set(key, regex);
			const cachedRegex = localCache.get(key);

			expect(true).toBe(cachedRegex.test(match));
			expect(false).toBe(cachedRegex.test(noMatch));
		});
	});

	describe("mset", function() {
		beforeAll(function() {
			state = {
				keyValueSet: [
					{
						key: randomString(10),
						val: randomString(10),
					},
					{
						key: randomString(10),
						val: randomString(10),
					},
				],
			};
		});

		it("mset an array of key value pairs", function() {
			const res = localCacheMset.mset(state.keyValueSet);
			expect(true).toBe(res);
			expect(2).toBe(localCacheMset.getStats().keys);
		});

		it("mset - integer key", function() {
			localCacheMset.flushAll();
			state.keyValueSet[0].key = randomNumber(10);
			const res = localCacheMset.mset(state.keyValueSet);
			expect(true).toBe(res);
			expect(2).toBe(localCacheMset.getStats().keys);
		});

		it("mset - boolean key throw error", function() {
			localCacheMset.flushAll();
			state.keyValueSet[0].key = true;

			expect(() => localCacheMset.mset(state.keyValueSet)).toThrow({
				name: "EKEYTYPE",
				message: "The key argument has to be of type `string` or `number`. Found: `boolean`",
			});
		});

		it("mset - object key throw error", function() {
			localCacheMset.flushAll();
			state.keyValueSet[0].key = {a: 1};

			expect(() => localCacheMset.mset(state.keyValueSet)).toThrow({
				name: "EKEYTYPE",
				message: "The key argument has to be of type `string` or `number`. Found: `object`",
			});
		});

		it("mset - ttl type error check", function() {
			localCacheMset.flushAll();
			state.keyValueSet[0].ttl = {a: 1};

			expect(() => localCacheMset.mset(state.keyValueSet)).toThrow({
				name: "ETTLTYPE",
				message: "The ttl argument has to be a number.",
			});
		});
	});
});
