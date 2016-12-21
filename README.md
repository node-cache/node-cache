node-cache
===========

[![Build Status](https://secure.travis-ci.org/mpneuried/nodecache.svg?branch=master)](http://travis-ci.org/mpneuried/nodecache)
[![Windows Tests](https://img.shields.io/appveyor/ci/mpneuried/nodecache.svg?label=Windows%20Test)](https://ci.appveyor.com/project/mpneuried/nodecache)
[![Dependency Status](https://david-dm.org/mpneuried/nodecache.svg)](https://david-dm.org/mpneuried/nodecache)
[![NPM version](https://badge.fury.io/js/node-cache.svg)](http://badge.fury.io/js/node-cache)
[![Coveralls Coverage](https://img.shields.io/coveralls/mpneuried/nodecache.svg)](https://coveralls.io/github/mpneuried/nodecache)

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/tcs-de/nodecache?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

[![NPM](https://nodei.co/npm/node-cache.png?downloads=true&downloadRank=true&stars=true)](https://nodei.co/npm/node-cache/)

# Simple and fast NodeJS internal caching.

A simple caching module that has `set`, `get` and `delete` methods and works a little bit like memcached.  
Keys can have a timeout (`ttl`) after which they expire and are deleted from the cache.  
All keys are stored in a single object so the practical limit is at around 1m keys.

**Since `4.1.0`**:
*Key-validation*: The keys can be given as either `string` or `number`, but are casted to a `string` internally anyway.  
All other types will either throw an error or call the callback with an error.


# Install

```bash
  npm install node-cache --save
```

Or just require the `node_cache.js` file to get the superclass

# Examples:

## Initialize (INIT):

```js
const NodeCache = require( "node-cache" );
const myCache = new NodeCache();
```

### Options

- `stdTTL`: *(default: `0`)* the standard ttl as number in seconds for every generated cache element.  
`0` = unlimited
- `checkperiod`: *(default: `600`)* The period in seconds, as a number, used for the automatic delete check interval.  
`0` = no periodic check.
- `errorOnMissing`: *(default: `false`)* en/disable throwing or passing an error to the callback if attempting to `.get` a missing or expired value.
- `useClones`: *(default: `true`)* en/disable cloning of variables. If `true` you'll get a copy of the cached variable. If `false` you'll save and get just the reference.  
**Note:** `true` is recommended, because it'll behave like a server-based caching. You should set `false` if you want to save mutable objects or other complex types with mutability involved and wanted.

```js
const NodeCache = require( "node-cache" );
const myCache = new NodeCache( { stdTTL: 100, checkperiod: 120 } );
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

> Note: If the key expires based on it's `ttl` it will be deleted entirely from the internal data object.

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
Returns a `undefined` if not found or expired.
If the value was found it returns an object with the `key` `value` pair.

```js
myCache.get( "myKey", function( err, value ){
  if( !err ){
    if(value == undefined){
      // key not found
    }else{
      console.log( value );
      //{ my: "Special", variable: 42 }
      // ... do something ...
    }
  }
});
```

**Since `1.0.0`**:  
Callback is now optional. You can also use synchronous syntax.

```js
value = myCache.get( "myKey" );
if ( value == undefined ){
  // handle miss!
}
// { my: "Special", variable: 42 }
```

**Since `2.0.0`**:  

The return format changed to a simple value and a `ENOTFOUND` error if not found *( as `callback( err )` or on sync call as result instance of `Error` )*.

**Since `2.1.0`**:

The return format changed to a simple value, but a due to discussion in #11 a miss shouldn't return an error.
So after 2.1.0 a miss returns `undefined`.

**Since `3.1.0`**
`errorOnMissing` option added

```js
try{
    value = myCache.get( "not-existing-key", true );
} catch( err ){
    // ENOTFOUND: Key `not-existing-key` not found
}
```

## Get multiple keys (MGET):

`myCache.mget( [ key1, key2, ... ,keyn ], [callback] )`

Gets multiple saved values from the cache.
Returns an empty object `{}` if not found or expired.
If the value was found it returns an object with the `key` `value` pair.

```js
myCache.mget( [ "myKeyA", "myKeyB" ], function( err, value ){
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
value = myCache.mget( [ "myKeyA", "myKeyB" ] );
/*
  {
    "myKeyA": { my: "Special", variable: 123 },
    "myKeyB": { the: "Glory", answer: 42 }
  }
*/
```

**Since `2.0.0`**:  

The method for mget changed from `.get( [ "a", "b" ] )` to `.mget( [ "a", "b" ] )`

## Delete a key (DEL):

`myCache.del( key, [callback] )`

Delete a key. Returns the number of deleted entries. A delete will never fail.

```js
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
value = myCache.del( "A" );
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
value = myCache.del( "A" );
// 1

value = myCache.del( [ "B", "C" ] );
// 2

value = myCache.del( [ "A", "B", "C", "D" ] );
// 1 - because A, B and C not exists
```

## Change TTL (TTL):

`myCache.ttl( key, ttl, [callback] )`

Redefine the ttl of a key. Returns true if the key has been found and changed. Otherwise returns false.  
If the ttl-argument isn't passed the default-TTL will be used.

The key will be deleted when passing in a `ttl < 0`.

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

## Get TTL (getTTL):

`myCache.getTtl( key, [callback] )`

Receive the ttl of a key.
You will get:
- `undefined` if the key does not exist
- `0` if this key has no ttl
- a timestamp in ms until the key expires

```js
myCache = new NodeCache( { stdTTL: 100 } )

// Date.now() = 1456000500000
myCache.set( "ttlKey", "MyExpireData" )
myCache.set( "noTtlKey", 0, "NonExpireData" )

ts = myCache.getTtl( "ttlKey" )
// ts wil be approximately 1456000600000

myCache.getTtl( "ttlKey", function( err, ts ){
  if( !err ){
    // ts wil be approximately 1456000600000
  }
});
// ts wil be approximately 1456000600000

ts = myCache.getTtl( "noTtlKey" )
// ts = 0

ts = myCache.getTtl( "unknownKey" )
// ts = undefined

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

## Close the cache:

`myCache.close()`

This will clear the interval timeout which is set on check period option.

```js
myCache.close();
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
You will get the `key` and the deleted `value` as callback arguments.

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


## Breaking changes

### version `2.x`

Due to the [Issue #11](https://github.com/mpneuried/nodecache/issues/11) the return format of the `.get()` method has been changed!

Instead of returning an object with the key `{ "myKey": "myValue" }` it returns the value itself `"myValue"`.

### version `3.x`

Due to the [Issue #30](https://github.com/mpneuried/nodecache/issues/30) and [Issue #27](https://github.com/mpneuried/nodecache/issues/27) variables will now be cloned.  
This chould break your code, because for some variable types ( e.g. Promise ) its not possible to clone them.  
You can disable the cloning by setting the option `useClones: false`. In this case it's compatible with version `2.x`.

## Benchmarks

### Version 1.1.x

After adding io.js to the travis test here are the benchmark results for set and get of 100000 elements.
But be careful with this results, because it has been executed on travis machines, so it is not guaranteed, that it was executed on similar hardware.

**node.js `0.10.36`**  
SET: `324`ms ( `3.24`µs per item )  
GET: `7956`ms ( `79.56`µs per item )   

**node.js `0.12.0`**  
SET: `432`ms ( `4.32`µs per item )  
GET: `42767`ms ( `427.67`µs per item )   

**io.js `v1.1.0`**  
SET: `510`ms ( `5.1`µs per item )  
GET: `1535`ms ( `15.35`µs per item )   

### Version 2.0.x

Again the same benchmarks by travis with version 2.0

**node.js `0.6.21`**  
SET: `786`ms ( `7.86`µs per item )  
GET: `56`ms ( `0.56`µs per item )   

**node.js `0.10.36`**  
SET: `353`ms ( `3.53`µs per item )
GET: `41`ms ( `0.41`µs per item )   

**node.js `0.12.2`**  
SET: `327`ms ( `3.27`µs per item )  
GET: `32`ms ( `0.32`µs per item )   

**io.js `v1.7.1`**  
SET: `238`ms ( `2.38`µs per item )  
GET: `34`ms ( `0.34`µs per item )  

> As you can see the version 2.x will increase the GET performance up to 200x in node 0.10.x.
This is possible because the memory allocation for the object returned by 1.x is very expensive.

### Version 3.0.x

*see [travis results](https://travis-ci.org/mpneuried/nodecache/builds/64560503)*

**node.js `0.6.21`**  
SET: `786`ms ( `7.24`µs per item )  
GET: `56`ms ( `1.14`µs per item )   

**node.js `0.10.38`**  
SET: `353`ms ( `5.41`µs per item )
GET: `41`ms ( `1.23`µs per item )   

**node.js `0.12.4`**  
SET: `327`ms ( `4.63`µs per item )  
GET: `32`ms ( `0.60`µs per item )   

**io.js `v2.1.0`**  
SET: `238`ms ( `4.06`µs per item )  
GET: `34`ms ( `0.67`µs per item )

> until the version 3.0.x the object cloning is included, so we lost a little bit of the performance

### Version 3.1.x

**node.js `v0.10.41`**  
SET: `305ms`  ( `3.05µs` per item )  
GET: `104ms`  ( `1.04µs` per item )

**node.js `v0.12.9`**  
SET: `337ms`  ( `3.37µs` per item )  
GET: `167ms`  ( `1.67µs` per item )

**node.js `v4.2.6`**  
SET: `356ms`  ( `3.56µs` per item )  
GET: `83ms`  ( `0.83µs` per item )

## Compatibility

This module should work well back until node `0.6.x`.
But it's only tested until version `0.10.x` because the build dependencies are not installable ;-) .

## Release History
|Version|Date|Description|
|:--:|:--:|:--|
|4.1.1|2016-12-21|fix internal check interval for node < 0.10.25, thats teh default node for ubuntu 14.04. Thanks to [Jimmy Hwang](https://github.com/JimmyHwang) for for the pull [#78](https://github.com/mpneuried/nodecache/pull/78); added more docker tests|
|4.1.0|2016-09-23|Added tests for different key types; Added key validation (must be `string` or `number`); Fixed `.del` bug where trying to delete a `number` key resulted in no deletion at all.|
|4.0.0|2016-09-20|Updated tests to mocha; Fixed `.ttl` bug to not delete key on `.ttl( key, 0 )`. This is also relevant if `stdTTL=0`. *This causes the breaking change to `4.0.0`.*|
|3.2.1|2016-03-21|Updated lodash to 4.x.; optimized grunt |
|3.2.0|2016-01-29|Added method `getTtl` to get the time when a key expires. See [#49](https://github.com/mpneuried/nodecache/issues/49)|
|3.1.0|2016-01-29|Added option `errorOnMissing` to throw/callback an error o a miss during a `.get( "key" )`. Thanks to [David Godfrey](https://github.com/david-byng) for the pull [#45](https://github.com/mpneuried/nodecache/pull/45). Added docker files and a script to run test on different node versions locally|
|3.0.1|2016-01-13|Added `.unref()` to the checkTimeout so until node `0.10` it's not necessary to call `.close()` when your script is done. Thanks to [Doug Moscrop](https://github.com/dougmoscrop) for the pull [#44](https://github.com/mpneuried/nodecache/pull/44).|
|3.0.0|2015-05-29|Return a cloned version of the cached element and save a cloned version of a variable. This can be disabled by setting the option `useClones:false`. (Thanks for #27 to [cheshirecatalyst](https://github.com/cheshirecatalyst) and for #30 to [Matthieu Sieben](https://github.com/matthieusieben))|
|~~2.2.0~~|~~2015-05-27~~|REVOKED VERSION, because of conficts. See [Issue #30](https://github.com/mpneuried/nodecache/issues/30). So `2.2.0` is now `3.0.0`|
|2.1.1|2015-04-17|Passed old value to the `del` event. Thanks to [Qix](https://github.com/qix) for the pull.|
|2.1.0|2015-04-17|Changed get miss to return `undefined` instead of an error. Thanks to all [#11](https://github.com/mpneuried/nodecache/issues/11) contributors |
|2.0.1|2015-04-17|Added close function (Thanks to [ownagedj](https://github.com/ownagedj)). Changed the development environment to use grunt.|
|2.0.0|2015-01-05|changed return format of `.get()` with a error return on a miss and added the `.mget()` method. *Side effect: Performance of .get() up to 330 times faster!*|
|1.1.0|2015-01-05|added `.keys()` method to list all existing keys|
|1.0.3|2014-11-07|fix for setting numeric values. Thanks to [kaspars](https://github.com/kaspars) + optimized key ckeck.|
|1.0.2|2014-09-17|Small change for better ttl handling|
|1.0.1|2014-05-22|Readme typos. Thanks to [mjschranz](https://github.com/mjschranz)|
|1.0.0|2014-04-09|Made `callback`s optional. So it's now possible to use a syncron syntax. The old syntax should also work well. Push : Bugfix for the value `0`|
|0.4.1|2013-10-02|Added the value to `expired` event|
|0.4.0|2013-10-02|Added nodecache events|
|0.3.2|2012-05-31|Added Travis tests|

[![NPM](https://nodei.co/npm-dl/node-cache.png?months=6)](https://nodei.co/npm/node-cache/)

## Other projects

|Name|Description|
|:--|:--|
|[**rsmq**](https://github.com/smrchy/rsmq)|A really simple message queue based on redis|
|[**redis-heartbeat**](https://github.com/mpneuried/redis-heartbeat)|Pulse a heartbeat to redis. This can be used to detach or attach servers to nginx or similar problems.|
|[**systemhealth**](https://github.com/mpneuried/systemhealth)|Node module to run simple custom checks for your machine or it's connections. It will use [redis-heartbeat](https://github.com/mpneuried/redis-heartbeat) to send the current state to redis.|
|[**rsmq-cli**](https://github.com/mpneuried/rsmq-cli)|a terminal client for rsmq|
|[**rest-rsmq**](https://github.com/smrchy/rest-rsmq)|REST interface for.|
|[**redis-sessions**](https://github.com/smrchy/redis-sessions)|An advanced session store for NodeJS and Redis|
|[**connect-redis-sessions**](https://github.com/mpneuried/connect-redis-sessions)|A connect or express middleware to simply use the [redis sessions](https://github.com/smrchy/redis-sessions). With [redis sessions](https://github.com/smrchy/redis-sessions) you can handle multiple sessions per user_id.|
|[**redis-notifications**](https://github.com/mpneuried/redis-notifications)|A redis based notification engine. It implements the rsmq-worker to safely create notifications and recurring reports.|
|[**nsq-logger**](https://github.com/mpneuried/nsq-logger)|Nsq service to read messages from all topics listed within a list of nsqlookupd services.|
|[**nsq-topics**](https://github.com/mpneuried/nsq-topics)|Nsq helper to poll a nsqlookupd service for all it's topics and mirror it locally.|
|[**nsq-nodes**](https://github.com/mpneuried/nsq-nodes)|Nsq helper to poll a nsqlookupd service for all it's nodes and mirror it locally.|
|[**nsq-watch**](https://github.com/mpneuried/nsq-watch)|Watch one or many topics for unprocessed messages.|
|[**hyperrequest**](https://github.com/mpneuried/hyperrequest)|A wrapper around [hyperquest](https://github.com/substack/hyperquest) to handle the results|
|[**task-queue-worker**](https://github.com/smrchy/task-queue-worker)|A powerful tool for background processing of tasks that are run by making standard http requests
|[**soyer**](https://github.com/mpneuried/soyer)|Soyer is small lib for server side use of Google Closure Templates with node.js.|
|[**grunt-soy-compile**](https://github.com/mpneuried/grunt-soy-compile)|Compile Goggle Closure Templates ( SOY ) templates including the handling of XLIFF language files.|
|[**backlunr**](https://github.com/mpneuried/backlunr)|A solution to bring Backbone Collections together with the browser fulltext search engine Lunr.js|
|[**domel**](https://github.com/mpneuried/domel)|A simple dom helper if you want to get rid of jQuery|
|[**obj-schema**](https://github.com/mpneuried/obj-schema)|Simple module to validate an object by a predefined schema|

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
