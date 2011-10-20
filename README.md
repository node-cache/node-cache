# Simple and fast nodejs internal chaching.

Simple caching module to save values inbetween nodejs.  
It is possible to define a time to live. So the values will be deleted after they has been expired.

*written in coffee-script*

## Install

<pre>
  npm install node-cache
</pre>

Or just require the `node_cache.js` file to get the superclass

## How to use

initialize:

<pre>
  var NodeCache = require( "node-cache" );
  var myCache = new NodeCache();
</pre>

## nodecache.set( key, val, [ ttl ], callback )

Sets a `key` `value` pair. It is possible to define an `ttl` ( default: see options ).  
Returns `true` on success.

Possible `ttl` examples are:

- `10`: 10 ms
- `10ms`: 10 ms
- `1s`: 1 Second
- `5m`: 5 Minutes
- `2h`: 2 Hours
- `4d`: 4 Days 



<pre>
  obj = { my: "Special", variable: 42 };

  myCache.set( "myKey", obj, function( err, success ){
    if( !err && success ){
      console.log( success );
      // true
      
      ... do something ...
    }
  });
</pre>

## nodecache.get( key, callback )

Gets a saved value.  
Returns an empty object if not found or expired.
If the value has been found it returns an object with the `key` `value` pair.

<pre>
  myCache.get( "myKey", function( err, value ){
    if( !err ){
      console.log( value );
      // { "myKey": { my: "Special", variable: 42 } }
      
      ... do something ...
    }
  });
</pre>

## nodecache.del( key, callback )

Delete a saved value.  
Returns `true` on success.

<pre>
  myCache.del( "myKey", function( err, value ){
    if( !err ){
      console.log( value );
      // { "myKey": { my: "Special", variable: 42 } }
      
      ... do something ...
    }
  });
</pre>

## nodecache.getStats()

Returns the statistics.  

<pre>
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
</pre>

## nodecache.checkData()

Run global check to delete expired data.  

<pre>
  myCache.checkData();
</pre>

## Work in progress

`node-cache` is work in progress. Your ideas, suggestions etc. are very welcome.

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