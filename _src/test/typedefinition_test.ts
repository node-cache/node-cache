
import NodeCache = require('../../');

import Options = NodeCache.Options;
import Stats = NodeCache.Stats;
import Callback = NodeCache.Callback;

interface TypeSample {
	a: number;
	b: string;
	c: boolean;
}

{
	let options: Options;
	let cache: NodeCache.NodeCache;
	cache = new NodeCache();
	cache = new NodeCache(options);
}

{
	let cache: NodeCache;
	let key: string;
	let cb: Callback<TypeSample>;
	let result: TypeSample | undefined;
	result = cache.get<TypeSample>(key);
	result = cache.get<TypeSample>(key, cb);
}

{
	let cache: NodeCache;
	let keys: string[];
	let cb: Callback<{ [key: string]: TypeSample }>;
	let result: { [key: string]: TypeSample };
	result = cache.mget<TypeSample>(keys);
	result = cache.mget<TypeSample>(keys, cb);
}

{
	let cache: NodeCache;
	let key: string;
	let value: TypeSample;
	let ttl: number | string;
	let cb: Callback<boolean>;
	let result: boolean;
	result = cache.set<TypeSample>(key, value);
	result = cache.set<TypeSample>(key, value, ttl);
	result = cache.set<TypeSample>(key, value, ttl, cb);
	result = cache.set<TypeSample>(key, value, cb);
}

{
	let cache: NodeCache;
	let keys: string | string[];
	let cb: Callback<number>;
	let result: number;
	result = cache.del(keys);
	result = cache.del(keys, cb);
}

{
	let cache: NodeCache;
	let key: string;
	let ttl: number;
	let cb: Callback<boolean>;
	let result: boolean;
	result = cache.ttl(key);
	result = cache.ttl(key, ttl);
	result = cache.ttl(key, ttl, cb);
	result = cache.ttl(key, cb);
}

{
	let cache: NodeCache;
	let cb: Callback<string[]>;
	let result: string[];
	result = cache.keys();
	result = cache.keys(cb);
}

{
	let cache: NodeCache;
	let result: Stats;
	result = cache.getStats();
}

{
	let cache: NodeCache;
	let cb: Callback<Boolean>;
	let key: string;
	let number: number;
	let result1: number | undefined;
	let result2: Boolean;
	result1 = cache.getTtl(key);
	result2 = cache.getTtl(key, cb);
}

{
	let cache: NodeCache;
	let cb: Callback<Boolean>;
	let key: string;
	let number: number;
	let result1: number | undefined;
	let result2: Boolean;
	result1 = cache.getTs(key);
	result2 = cache.getTs(key, cb);
}

/* tslint:disable void-return no-void-expression */
{
	let cache: NodeCache;
	let result: void;
	result = cache.flushAll();
}

{
	let cache: NodeCache;
	let result: void;
	result = cache.close();
}
/* tslint:enable void-return */
