# Simple and fast NodeJS internal caching.

A simple caching module that has `set`, `get` and `delete` methods and works a little bit like memcached.
Keys can have a timeout after which they expire and are cleaned from the cache.  
All keys are stored in a single object so the practical limit is at around 1m keys.

*Written in coffee-script*

## Install

<pre>
  npm install node-cache
</pre>

Or just require the `node_cache.js` file to get the superclass

## Examples:

### Initialize:

```
var NodeCache = require( "node-cache" );
var myCache = new NodeCache();
```

### Store a key (SET):

`myCache.set( key, val, [ ttl ], callback )`

Sets a `key` `value` pair. It is possible to define a `ttl` (in seconds).  
Returns `true` on success.

```
obj = { my: "Special", variable: 42 };
myCache.set( "myKey", obj, function( err, success ){
  if( !err && success ){
    console.log( success );
    // true
    // ... do something ...
  }
});
```

### Retrieve a key (GET):

`myCache.get( key, callback )`

Gets a saved value from the cache.
Returns an empty object `{}` if not found or expired.
If the value was found it returns an object with the `key` `value` pair.

```
myCache.get( "myKey", function( err, value ){
  if( !err ){
    console.log( value );
    // { "myKey": { my: "Special", variable: 42 } }
    // ... do something ...
  }
});
```
### Delete a key

`myCache.del( key, callback )`

Delete a key. Returns `true`. A delete will never fail.

```
myCache.del( "myKey", function( err, value ){
  if( !err ){
    console.log( value );
    // { "myKey": { my: "Special", variable: 42 } }
    // ... do something ...
  }
});
```

### Statistics

`myCache.getStats()`

Returns the statistics.  

```
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

## Work in progress

`nodecache` is work in progress. Your ideas, suggestions etc. are very welcome.

## License 

(The MIT License)

Copyright (c) 2010 TCS &lt;dev (at) tcs.de&gt;

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