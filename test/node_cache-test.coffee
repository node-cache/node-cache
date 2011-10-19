# define runtime environment
root._ = require("../node_modules/underscore")
root.utils = require( "../lib/utils" )

VCache = require "../lib/node_cache"
localCache = new VCache( stdTTL: '15m' )

# test helper
randomString = ( length, withnumbers = true ) ->
	chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	chars += "0123456789" if withnumbers

	string_length = length or 5
	randomstring = ""
	i = 0
	
	while i < string_length
		rnum = Math.floor(Math.random() * chars.length)
		randomstring += chars.substring(rnum, rnum + 1)
		i++
	randomstring

vs = []
ks = []

# define tests
module.exports = 
	"test node_cache#general": (beforeExit, assert) ->

		done = false

		value = randomString( 100 )
		key = randomString( 10 )
		localCache.set key, value, 0, ( err, res )->
			localCache.get key, ( err, res )->
				done = true
				assert.equal value, res
				console.log( "general stats:", localCache.getStats() )

		beforeExit ->
			assert.equal( true, done, "not exited" )

	"test node_cache#many": (beforeExit, assert) ->
		n = 0
		count = 1000000
		val = randomString( 20 )
		for i in [1..count]
			key = randomString( 7 )

			ks.push key
		
		time = new Date().getTime()
		for key in ks	
			localCache.set key, val, 0, ( err, res )->
				return
		
		console.log( "time:", new Date().getTime() - time )
		for key in ks
			localCache.get key, ( err, res )->
				n++
				assert.equal val, res
		
		console.log( "time:", new Date().getTime() - time )
		console.log( "general stats:", localCache.getStats() )
		
		beforeExit ->

			assert.equal( n, count)
			

	"test node_cache#delete": (beforeExit, assert) ->
		time = new Date().getTime()
		n = 0
		count = 10000
		startKeys = localCache.getStats().keys
		for i in [1..count]
			ri = Math.floor(Math.random() * vs.length)
			localCache.del ks[ i ], ( err, success )->
				n++
				assert.equal( true, success )
				assert.isNull( err, err )
			
		console.log( "time:", new Date().getTime() - time )
		console.log( "general stats:", localCache.getStats() )
		
		beforeExit ->

			assert.equal( n, count)
			assert.equal( localCache.getStats().keys, startKeys - n )
				