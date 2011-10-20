# define runtime environment
_ = require( "underscore" )

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

		n = 0

		start = _.clone( localCache.getStats() )
		
		value = randomString( 100 )
		value2 = randomString( 100 )
		key = randomString( 10 )

		# test insert
		localCache.set key, value, 0, ( err, res )->
			assert.isNull( err, err )
			n++

			# check stats
			assert.equal 1, localCache.getStats().keys - start.keys

			# try to get
			localCache.get key, ( err, res )->
				n++
				# generate a predicted value
				pred = {}
				pred[ key ] = value
				assert.eql pred, res

			# get an undefined key
			localCache.get "xxx", ( err, res )->
				n++
				assert.isNull( err, err )
				assert.eql {}, res
			
			# try to delete an undefined key
			localCache.del "xxx", ( err, res )->
				n++
				assert.isNull( err, err )
				assert.ok res
			
			# test update
			localCache.set key, value2, 0, ( err, res )->
				n++
				assert.isNull( err, err )
				assert.ok( res, err )
				
				# check update
				localCache.get key, ( err, res )->
					n++
					# generate a predicted value
					pred = {}
					pred[ key ] = value2
					assert.eql pred, res

					# check if stats didn't changed
					assert.equal 1, localCache.getStats().keys - start.keys

			# try to delete the defined key
			localCache.del key, ( err, res )->
				n++
				assert.isNull( err, err )
				assert.ok res

				# check stats
				assert.equal 0, localCache.getStats().keys - start.keys

				# try to get the deleted key
				localCache.get key, ( err, res )->
					n++
					assert.isNull( err, err )
					assert.eql {}, res

		beforeExit ->
			assert.equal( 8, n, "not exited" )

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
				pred = {}
				pred[ key ] = val
				assert.eql pred, res
		
		console.log( "TIME-GET:", new Date().getTime() - time )
		console.log( "MANY STATS:", localCache.getStats() )
		
		beforeExit ->

			assert.equal( n, count)
			

	"delete": (beforeExit, assert) ->
		n = 0
		count = 10000
		startKeys = localCache.getStats().keys
		
		# test deletes
		for i in [1..count]
			ri = Math.floor(Math.random() * vs.length)
			localCache.del ks[ i ], ( err, success )->
				n++
				assert.isNull( err, err )
				assert.ok( success )
		
		for i in [1..count]
			ri = Math.floor(Math.random() * vs.length)
			localCache.del ks[ i ], ( err, success )->
				n++
				assert.ok( success )
				assert.isNull( err, err )
		
		# check stats for only a single deletion	
		assert.equal( localCache.getStats().keys, startKeys - count )
		
		beforeExit ->
			# check  successfull runs
			assert.equal( n, count * 2)
	
	"ttl": (beforeExit, assert) ->
		val = randomString( 20 )
		key = randomString( 7 )
		key2 = randomString( 7 )
		n = 0

		# set a key with ttl
		localCache.set key, val, 500, ( err, res )->
			assert.isNull( err, err )
			assert.ok( res )

			# check the key immediately
			localCache.get key, ( err, res )->
				assert.isNull( err, err )
				pred = {}
				pred[ key ] = val
				assert.eql( pred, res )
		
		# set another key
		localCache.set key2, val, 800, ( err, res )->
			assert.isNull( err, err )
			assert.ok( res )

			# check the key immediately
			localCache.get key2, ( err, res )->
				assert.isNull( err, err )
				pred = {}
				pred[ key2 ] = val
				assert.eql( pred, res )
		
		# check key before lifetime end
		setTimeout( ->
			++n;
			localCache.get key, ( err, res )->
				assert.isNull( err, err )
				pred = {}
				pred[ key ] = val
				assert.eql( pred, res )
		, 400 )

		# check key after lifetime end
		setTimeout( ->
			++n;
			localCache.get key, ( err, res )->
				assert.isNull( err, err )
				assert.eql( {}, res )
		, 600 )

		# check second key before lifetime end
		setTimeout( ->
			++n;
			localCache.get key2, ( err, res )->
				assert.isNull( err, err )
				pred = {}
				pred[ key2 ] = val
				assert.eql( pred, res )
				assert.eql( pred, res )
		, 600 )
	
	"stats": (beforeExit, assert) ->
		n = 0
		start = _.clone( localCache.getStats() )
		count = 5
		keys = []
		vals = []

		# add count`*2 elements
		for i in [1..count*2]
			key = randomString( 7 )
			val = randomString( 50 )
			keys.push key
			vals.push val

			localCache.set key, val, 0, ( err, success )->
				n++
				assert.isNull( err, err )
				assert.ok( success )
		
		# get and remove `count` elements 
		for i in [1..count]
			localCache.get keys[ i ], ( err, res )->
				n++
				pred = {}
				pred[ keys[ i ] ] = vals[ i ]
				assert.eql( pred, res )
				assert.isNull( err, err )

			localCache.del keys[ i ], ( err, success )->
				n++
				assert.isNull( err, err )
				assert.ok( success )
		
		# generate `count` misses
		for i in [1..count]
			# 4 char key should not exist
			localCache.get "xxxx", ( err, res )->
				++n
				assert.isNull( err, err )
				assert.eql( {}, res )

		end = localCache.getStats()
		
		# check predicted stats
		assert.equal( end.hits - start.hits, 5, "hits wrong" )
		assert.equal( end.misses - start.misses, 5, "misses wrong" )
		assert.equal( end.keys - start.keys, 5, "hits wrong" )
		assert.equal( end.ksize - start.ksize, 5*7, "hits wrong" )
		assert.equal( end.vsize - start.vsize, 5*50, "hits wrong" )
		
		beforeExit ->

			assert.equal( n, count*5 )