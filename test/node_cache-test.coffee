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
	"general": (beforeExit, assert) ->

		done = false

		value = randomString( 100 )
		key = randomString( 10 )
		localCache.set key, value, 0, ( err, res )->
			assert.isNull( err, err )
			localCache.get key, ( err, res )->
				done = true
				assert.equal value, res
				console.log( "general stats:", localCache.getStats() )

		beforeExit ->
			assert.equal( true, done, "not exited" )

	"many": (beforeExit, assert) ->
		n = 0
		count = 100000
		console.log "START MANY TEST/BENCHMARK.\nSet, Get and check #{count} elements"
		val = randomString( 20 )
		for i in [1..count]
			key = randomString( 7 )

			ks.push key
		
		time = new Date().getTime()
		for key in ks	
			localCache.set key, val, 0, ( err, res )->
				assert.isNull( err, err )
				return
		
		console.log( "TIME-SET:", new Date().getTime() - time )
		time = new Date().getTime()
		for key in ks
			localCache.get key, ( err, res )->
				n++
				assert.equal val, res
		
		console.log( "TIME-GET:", new Date().getTime() - time )
		console.log( "MANY STATS:", localCache.getStats() )
		
		beforeExit ->

			assert.equal( n, count)
			

	"delete": (beforeExit, assert) ->
		n = 0
		count = 10000
		startKeys = localCache.getStats().keys
		for i in [1..count]
			ri = Math.floor(Math.random() * vs.length)
			localCache.del ks[ i ], ( err, success )->
				n++
				assert.ok( success )
				assert.isNull( err, err )
			
		console.log( "DELETE STATS:", localCache.getStats() )
		assert.equal( localCache.getStats().keys, startKeys - n )
		
		beforeExit ->

			assert.equal( n, count)
	
	"ttl": (beforeExit, assert) ->
		val = randomString( 20 )
		key = randomString( 7 )
		key2 = randomString( 7 )
		n = 0

		localCache.set key, val, 500, ( err, res )->
			assert.isNull( err, err )
			assert.ok( res )
			localCache.get key, ( err, res )->
				assert.isNull( err, err )
				assert.equal( val, res )

		localCache.set key2, val, 800, ( err, res )->
			assert.isNull( err, err )
			assert.ok( res )
			localCache.get key2, ( err, res )->
				assert.isNull( err, err )
				assert.equal( val, res )
		
		setTimeout( ->
			++n;
			localCache.get key, ( err, res )->
				assert.isNull( err, err )
				assert.equal( val, res )
		, 400 )

		setTimeout( ->
			++n;
			localCache.get key, ( err, res )->
				assert.isNull( res, res )
				assert.equal( 'not-found', err.errorcode )
		, 600 )

		setTimeout( ->
			++n;
			localCache.get key2, ( err, res )->
				assert.isNull( err, err )
				assert.equal( val, res )
		, 600 )

		setTimeout( ->
			console.log( "TTL STATS:", localCache.getStats() )
		, 700 )
	
	"stats": (beforeExit, assert) ->
		n = 0
		start = _.clone( localCache.getStats() )
		count = 5
		keys = []

		# add count`*2 elements
		for i in [1..count*2]
			key = randomString( 7 )
			val = randomString( 50 )
			keys.push key

			localCache.set key, val, 0, ( err, success )->
				n++
				assert.ok( success )
				assert.isNull( err, err )
		
		# get and remove `count` elements 
		for i in [1..count]
			key = randomString( 7 )
			val = randomString( 50 )

			localCache.get keys[ i ], ( err, success )->
				n++
				assert.ok( success )
				assert.isNull( err, err )

			localCache.del keys[ i ], ( err, success )->
				n++
				assert.ok( success )
				assert.isNull( err, err )
		
		# generate `count` misses
		for i in [1..count]
			# 4 char key should not exist
			localCache.get "xxxx", ( err, res )->
				++n
				assert.isNull( res, res )
				assert.equal( 'not-found', err.errorcode )

		end = localCache.getStats()
		console.log start, end
		assert.equal( end.hits - start.hits, 5, "hits wrong" )
		assert.equal( end.misses - start.misses, 5, "misses wrong" )
		assert.equal( end.keys - start.keys, 5, "hits wrong" )
		assert.equal( end.ksize - start.ksize, 5*7, "hits wrong" )
		assert.equal( end.vsize - start.vsize, 5*50, "hits wrong" )
		
		beforeExit ->

			assert.equal( n, count*5 )