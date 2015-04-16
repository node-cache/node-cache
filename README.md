node-cache
===========

[![Build Status](https://secure.travis-ci.org/tcs-de/nodecache.png?branch=master)](http://travis-ci.org/tcs-de/nodecache)
[![Build Status](https://david-dm.org/tcs-de/nodecache.png)](https://david-dm.org/tcs-de/nodecache)
[![NPM version](https://badge.fury.io/js/node-cache.png)](http://badge.fury.io/js/node-cache)

[![NPM](https://nodei.co/npm/node-cache.png?downloads=true&downloadRank=true&stars=true)](https://nodei.co/npm/node-cache/)

# Simple and fast NodeJS internal caching.

A simple caching module that has `set`, `get` and `delete` methods and works a little bit like memcached.
Keys can have a timeout after which they expire and are cleaned from the cache.  
All keys are stored in a single object so the practical limit is at around 1m keys.

# Install

```bash
  npm install node-cache
```

Or just require the `node_cache.js` file to get the superclass

# Examples:

## Initialize (INIT):

```js
var NodeCache = require( "node-cache" );
var myCache = new NodeCache();
```

### Options

- `stdTTL`: *(default: `0`)* the standard ttl as number in seconds for every generated cache element.  
`0` = unlimited
- `checkperiod`: *(default: `600`)* The period in seconds, as a number, used for the automatic delete check interval.  
`0` = no periodic check.  
**Note:** If you use `checkperiod > 0` you script will not exit at the end, because a internal timeout will allways be active.

```js
var NodeCache = require( "node-cache" );
var myCache = new NodeCache( { stdTTL: 100, checkperiod: 120 } );
```

## Store a key (SET):

`myCache.set( key, val, [ ttl ], [callback] )`

Sets a `key` `value` pair. It is possible to define a `ttl` (in seconds).  
Returns `true` on success.

```js
obj = { my: "Special", variable: 42 };
myCache.set( "myKey", obj, function( err, success ){
  if( !err && success ){
    console.log( success );
    // true
    // ... do something ...
  }
});
```

**Since `1.0.0`**:  
Callback is now optional. You can also use synchronous syntax.

```js
obj = { my: "Special", variable: 42 };
success = myCache.set( "myKey", obj, 10000 );
// true
```


## Retrieve a key (GET):

`myCache.get( key, [callback] )`

Gets a saved value from the cache.
Returns an empty object `{}` if not found or expired.
If the value was found it returns an object with the `key` `value` pair.

```js
myCache.get( "myKey", function( err, value ){
  if( !err ){
    console.log( value );
    // { "myKey": { my: "Special", variable: 42 } }
    // ... do something ...
  }
});
```

**Since `1.0.0`**:  
Callback is now optional. You can also use synchronous syntax.

```js
value = myCache.get( "myKey" );
// { "myKey": { my: "Special", variable: 42 } }
```

## Get multiple keys (MGET):

`myCache.get( [ key1, key2, ... ,keyn ], [callback] )`

Gets multiple saved values from the cache.
Returns an empty object `{}` if not found or expired.
If the value was found it returns an object with the `key` `value` pair.

```js
myCache.get( [ "myKeyA", "myKeyB" ], function( err, value ){
  if( !err ){
    console.log( value );
    /*
      {
        "myKeyA": { my: "Special", variable: 123 },
        "myKeyB": { the: "Glory", answer: 42 }
      }
    */
    // ... do something ...
  }
});
```

**Since `1.0.0`**:  
Callback is now optional. You can also use synchronous syntax.

```js
value = myCache.get( [ "myKeyA", "myKeyB" ] );
/*
  {
    "myKeyA": { my: "Special", variable: 123 },
    "myKeyB": { the: "Glory", answer: 42 }
  }
*/
```

## Delete a key (DEL):

`myCache.del( key, [callback] )`

Delete a key. Returns the number of deleted entries. A delete will never fail.

```
myCache.del( "myKey", function( err, count ){
  if( !err ){
    console.log( count ); // 1
    // ... do something ...
  }
});
```

**Since `1.0.0`**:  
Callback is now optional. You can also use synchronous syntax.

```js
value = myCache.del( "myKeyA" );
// 1
```

## Delete multiple keys (MDEL):

`myCache.del( [ key1, key2, ... ,keyn ], [callback] )`

Delete multiple keys. Returns the number of deleted entries. A delete will never fail.

```js
myCache.del( [ "myKeyA", "myKeyB" ], function( err, count ){
  if( !err ){
    console.log( count ); // 2
    // ... do something ...
  }
});
```

**Since `1.0.0`**:  
Callback is now optional. You can also use synchronous syntax.

```js
value = myCache.del( [ "myKeyA", "myKeyB", "notExistendKey" ] );
// 2
```

## Change TTL (TTL):

`myCache.ttl( key, ttl, [callback] )`

Redefine the ttl of a key. Returns true if the key has been found and changed. Otherwise returns false.  
If the ttl-argument isn't passed the default-TTL will be used.

```js
myCache = new NodeCache( { stdTTL: 100 } )
myCache.ttl( "existendKey", 100, function( err, changed ){
  if( !err ){
    console.log( changed ); // true
    // ... do something ...
  }
});

myCache.ttl( "missingKey", 100, function( err, changed ){
  if( !err ){
    console.log( changed ); // false
    // ... do something ...
  }
});

myCache.ttl( "existendKey", function( err, changed ){
  if( !err ){
    console.log( changed ); // true
    // ... do something ...
  }
});
```

**Since `1.0.0`**:  
Callback is now optional. You can also use synchronous syntax.

```js
value = myCache.ttl( "existendKey", 100 );
// true
```

## List keys (KEYS)

`myCache.keys( [callback] )`

Returns an array of all existing keys.  

```js
// async
myCache.keys( function( err, mykeys ){
  if( !err ){
    console.log( mykeys );
   // [ "all", "my", "keys", "foo", "bar" ]
  }
});

// sync
mykeys = myCache.keys();

console.log( mykeys );
// [ "all", "my", "keys", "foo", "bar" ]

```

## Statistics (STATS):

`myCache.getStats()`

Returns the statistics.  

```js
myCache.getStats();
  /*
    {
      keys: 0,    // global key count
      hits: 0,    // global hit count
      misses: 0,  // global miss count
      ksize: 0,   // global key size count
      vsize: 0    // global value size count
    }
  */
```

## Flush all data (FLUSH):

`myCache.flushAll()`

Flush all data.  

```js
myCache.flushAll();
myCache.getStats();
  /*
    {
      keys: 0,    // global key count
      hits: 0,    // global hit count
      misses: 0,  // global miss count
      ksize: 0,   // global key size count
      vsize: 0    // global value size count
    }
  */
```

# Events

## set

Fired when a key has been added or changed.
You will get the `key` and the `value` as callback argument.

```js
myCache.on( "set", function( key, value ){
	// ... do something ...  
});
```

## del

Fired when a key has been removed manually or due to expiry.
You will get the `key` and `value` as callback arguments.

```js
myCache.on( "del", function( key, value ){
	// ... do something ...  
});
```

## expired

Fired when a key expires.
You will get the `key` and `value` as callback argument.

```js
myCache.on( "expired", function( key, value ){
	// ... do something ...  
});
```

## flush

Fired when the cache has been flushed.

```js
myCache.on( "flush", function(){
	// ... do something ...  
});
```

## Benchmarks

After adding io.js to the travis test here are the benchmark results for set and get of 100000 elements.
But be carefull with this results, because it has been executed on travis machines, so it is not guaranteed, that was executed on similar hardware.

**node.js `0.10.36`**  
SET: `324`ms ( `3.24`ns per item )  
GET: `7956`ms ( `79.56`ns per item )   

**node.js `0.12.0`**  
SET: `432`ms ( `4.32`ns per item )  
GET: `42767`ms ( `427.67`ns per item )   

**io.js `v1.1.0`**  
SET: `510`ms ( `5.1`ns per item )  
GET: `1535`ms ( `15.35`ns per item )   

## Release History
|Version|Date|Description|
|:--:|:--:|:--|
|v1.1.0|2014-11-07|added `.keys` method to list all existing keys|
|v1.0.3|2014-11-07|fix for setting numeric values. Thanks to [kaspars](https://github.com/kaspars) + optimized key ckeck.|
|v1.0.2|2014-09-17|Small change for better ttl handling|
|v1.0.1|2014-05-22|Readme typos. Thanks to [mjschranz](https://github.com/mjschranz)|
|v1.0.0|2014-04-09|Made `callback`s optional. So it's now possible to use a syncron syntax. The old syntax should also work well. Push : Bugfix for the value `0`|
|v0.4.1|2013-10-02|Added the value to `expired` event|
|v0.4.0|2013-10-02|Added nodecache events|
|v0.3.2|2012-05-31|Added Travis tests|

[![NPM](https://nodei.co/npm-dl/node-cache.png?months=6)](https://nodei.co/npm/node-cache/)

## Other projects

|Name|Description|
|:--|:--|
|[**rsmq**](https://github.com/smrchy/rsmq)|A really simple message queue based on Redis|
|[**redis-sessions**](https://github.com/smrchy/redis-sessions)|An advanced session store for NodeJS and Redis|
|[**connect-redis-sessions**](https://github.com/mpneuried/connect-redis-sessions)|A connect or express middleware to simply use the [redis sessions](https://github.com/smrchy/redis-sessions). With [redis sessions](https://github.com/smrchy/redis-sessions) you can handle multiple sessions per user_id.|
|[**redis-heartbeat**](https://github.com/mpneuried/redis-heartbeat)|Pulse a heartbeat to redis. This can be used to detach or attach servers to nginx or similar problems.|
|[**systemhealth**](https://github.com/mpneuried/systemhealth)|Node module to run simple custom checks for your machine or it's connections. It will use [redis-heartbeat](https://github.com/mpneuried/redis-heartbeat) to send the current state to redis.|
|[**task-queue-worker**](https://github.com/smrchy/task-queue-worker)|A powerful tool for background processing of tasks that are run by making standard http requests.|
|[**soyer**](https://github.com/mpneuried/soyer)|Soyer is small lib for serverside use of Google Closure Templates with node.js.|
|[**grunt-soy-compile**](https://github.com/mpneuried/grunt-soy-compile)|Compile Goggle Closure Templates ( SOY ) templates inclding the handling of XLIFF language files.|
|[**backlunr**](https://github.com/mpneuried/backlunr)|A solution to bring Backbone Collections together with the browser fulltext search engine Lunr.js|


# The MIT License (MIT)

Copyright © 2013 Mathias Peter, http://www.tcs.de

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
