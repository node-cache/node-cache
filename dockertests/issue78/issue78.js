var os = require('os');
console.log("Node Version: " + process.version + "\n");

var node_cache = require("node-cache");
var myCache = new node_cache( { stdTTL: 50, checkperiod: 2 } );
myCache.set("A:1", 123, 5);
myCache.set("A:2", 456, 10);

myCache.on("expired", function( key, value ){
  console.log(key + " is expired");
  // ... do something ...
});
console.log( "waiting ... " );

// add a timeout to prevent the script to exit
setTimeout( function(  ){
  console.log( "exit" );
}, 15000 )
