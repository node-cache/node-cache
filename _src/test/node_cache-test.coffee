# define runtime environment
_ = require( "lodash" )

VCache = require "../"
localCache = new VCache( stdTTL: 0 )
localCacheNoClone = new VCache( stdTTL: 0, useClones: false, checkperiod: 0 )
localCacheTTL = new VCache( stdTTL: 0.3, checkperiod: 0 )
# just for testing disable the check period
localCache._killCheckPeriod()
#localCacheTTL._killCheckPeriod() # disabled to test checkperiod = 0

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
		console.log "\nSTART GENERAL TEST: `" + VCache.version + "` on node:`#{process.version}`"



		n = 0

		start = _.clone( localCache.getStats() )
		
		value = randomString( 100 )
		value2 = randomString( 100 )
		key = randomString( 10 )


		localCache.once "del", ( _key, _val )->
			assert.equal( _key, key )
			assert.equal( _val, value2 )
			return


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
				assert.eql value, res
				return

			# try to get
			localCache.keys ( err, res )->
				n++
				pred = [ key ]
				assert.eql pred, res
				return

			# get an undefined key
			localCache.get "yxx", ( err, res )->
				n++
				assert.isNull( err, err )
				assert.isUndefined( res, res )
				return

			# catch an undefined key
			errorHandlerCallback = ( err, res )->
				n++
				assert.eql( err.name, "ENOTFOUND" )
				assert.eql( err.message, "Key `xxx` not found" )
				return
			localCache.get( "xxx", errorHandlerCallback, true )

			# catch an undefined key without callback
			try
				localCache.get( "xxy", true )
			catch err
				n++
				assert.eql( err.name, "ENOTFOUND" )
				assert.eql( err.message, "Key `xxy` not found" )

			# errorOnMissing option triggers throwing error automatically
			originalThrowOnMissingValue = localCache.options.errorOnMissing
			localCache.options.errorOnMissing = true
			try
				localCache.get( "xxz" )
			catch err
				n++
				assert.eql( err.name, "ENOTFOUND" )
				assert.eql( err.message, "Key `xxz` not found" )
			localCache.options.errorOnMissing = originalThrowOnMissingValue
			console.log localCache.options.errorOnMissing
			# try to delete an undefined key
			localCache.del "xxx", ( err, res )->
				n++
				assert.isNull( err, err )
				assert.equal( 0, res )
				return
			
			# test update
			localCache.set key, value2, 0, ( err, res )->
				n++
				assert.isNull( err, err )
				assert.ok( res, err )
				
				# check update
				localCache.get key, ( err, res )->
					n++
					# generate a predicted value
					pred = value2
					assert.eql pred, res

					# check if stats didn't changed
					assert.equal 1, localCache.getStats().keys - start.keys
					return
				return

			# try to delete the defined key
			localCache.del key, ( err, res )->
				localCache.removeAllListeners( "del" )
				n++
				assert.isNull( err, err )
				assert.equal 1, res

				# check stats
				assert.equal 0, localCache.getStats().keys - start.keys

				# try to get the deleted key
				localCache.get key, ( err, res )->
					n++
					assert.isNull( err, err )
					assert.isUndefined( res, res )
					return

				# set a key with 0
				localCache.set "zero", 0, 0, ( err, res )->
					n++
					assert.isNull( err, err )
					assert.ok( res, err )
					return

				# get a key with 0
				localCache.get "zero", ( err, res )->
					n++
					assert.isNull( err, err )
					assert.eql 0, res
					return
				return
			return
		
		if Promise?
			p = new Promise (fulfill, reject)-> fulfill('Some deferred value')
			p.then (value)->
				assert.eql value, 'Some deferred value'
				return
			
			localCacheNoClone.set( "promise", p )
			q = localCacheNoClone.get( "promise" )
			try
				q.then (value)->
					n++
					return
			catch _err
				assert.ok false, _err
				return
			
		else
			console.log "No Promise test, because not availible in this node version"

		beforeExit ->
			_count = 14
			if Promise?
				_count += 1
			
			assert.equal( _count, n, "not exited" )
			return
		return

	"general sync": (beforeExit, assert) ->
		console.log "\nSTART GENERAL TEST SYNC"

		localCache.flushAll()

		start = _.clone( localCache.getStats() )
		
		value = randomString( 100 )
		value2 = randomString( 100 )
		key = randomString( 10 )

		localCache.once "del", ( _key, _val )->
			assert.equal( _key, key )
			assert.equal( _val, value2 )
			return

		# test insert
		assert.ok localCache.set( key, value, 0 )

		# check stats
		assert.equal 1, localCache.getStats().keys - start.keys

		# try to get
		res = localCache.get( key )
		# generate a predicted value
		assert.eql value, res

		res = localCache.keys()
		pred = [ key ]
		assert.eql pred, res

		# get an undefined key
		res = localCache.get( "xxx" )
		assert.isUndefined( res, res )

		# try to delete an undefined key
		res = localCache.del( "xxx" )
		assert.equal( 0, res )
		
		# test update
		res = localCache.set( key, value2, 0 )
		assert.ok( res, res )
			
		# check update
		res = localCache.get( key )
		# generate a predicted value
		assert.eql value2, res

		# check if stats didn't changed
		assert.equal 1, localCache.getStats().keys - start.keys

		# try to delete the defined key
		res = localCache.del( key )
		localCache.removeAllListeners( "del" )
		assert.equal 1, res

		# check stats
		assert.equal 0, localCache.getStats().keys - start.keys

		# try to get the deleted key
		res = localCache.get( key )
		assert.isUndefined( res, res )
		
		# set multiple keys to test the multi delete by array
		res = localCache.set( "mulitA", 23 )
		assert.ok( res, res )
		res = localCache.set( "mulitB", 23 )
		assert.ok( res, res )
		res = localCache.set( "mulitC", 23 )
		assert.ok( res, res )
		
		res = localCache.get( "mulitA" )
		assert.equal( res, 23 )
		res = localCache.get( "mulitB" )
		assert.equal( res, 23 )
		res = localCache.get( "mulitC" )
		assert.equal( res, 23 )
		
		res = localCache.del( [ "mulitA", "mulitB" ] )
		assert.equal( 2, res )
		
		# try to get the deleted key
		res = localCache.get( "mulitA" )
		assert.isUndefined( res, res )
		res = localCache.get( "mulitB" )
		assert.isUndefined( res, res )
		res = localCache.get( "mulitC" )
		assert.equal( res, 23 )
		
		res = localCache.del( [ "mulitC" ] )
		assert.equal( 1, res )
		res = localCache.get( "mulitC" )
		assert.isUndefined( res, res )
		
		res = localCache.del( [ "mulitA", "mulitB", "mulitC" ] )
		assert.equal( 0, res )
		
		# set a key with 0
		res = localCache.set( "zero", 0, 0 )
		assert.ok( res, res )

		# get a key with 0
		res = localCache.get( "zero" )
		assert.eql 0, res
		
		# set a key with 0
		tObj =
			a: 1
			b:
				x: 2
				y: 3
		res = localCache.set( "clone", tObj, 0 )
		assert.ok( res, res )
		
		tObj.b.x = 666
		res = localCache.get( "clone" )
		assert.equal 2, res.b.x
		
		res.b.y = 42
		
		res2 = localCache.get( "clone" )
		assert.equal 3, res2.b.y
		
		return

	"flush": (beforeExit, assert) ->
		console.log "\nSTART FLUSH TEST"
		n = 0
		count = 100
		startKeys = localCache.getStats().keys

		# set `count` values
		ks = []
		val = randomString( 20 )
		for i in [1..count]
			key = randomString( 7 )
			ks.push key
		
		for key in ks
			localCache.set key, val, 0, ( err, res )->
				n++
				assert.isNull( err, err )
				return
		
		# check if all data set
		assert.equal( localCache.getStats().keys, startKeys + count )

		localCache.flushAll( false )

		# check for empty data
		assert.equal( localCache.getStats().keys, 0 )
		assert.eql( localCache.data, {} )


		beforeExit ->
			# check  successfull runs
			assert.equal( n, count + 0 )
			return

		return

	"many": (beforeExit, assert) ->
		n = 0
		count = 100000

		console.log "\nSTART MANY TEST/BENCHMARK.\nSet, Get and check #{count} elements"
		val = randomString( 20 )
		ks = []
		for i in [1..count]
			key = randomString( 7 )
			ks.push key
		
		time = new Date().getTime()
		for key in ks
			assert.ok localCache.set( key, val, 0 )

		_dur =  new Date().getTime() - time
		console.log( "BENCHMARK for SET:", "#{_dur}ms", " ( #{_dur/count}ms per item ) " )
		
		time = new Date().getTime()
		for key in ks
			n++
			assert.eql val, localCache.get( key )
		
		_dur = new Date().getTime() - time
		console.log( "BENCHMARK for GET:", "#{_dur}ms", " ( #{_dur/count}ms per item ) " )
		console.log( "BENCHMARK STATS:", localCache.getStats() )
		
		beforeExit ->
			_stats = localCache.getStats()
			_keys = localCache.keys()
			assert.eql _stats.keys, _keys.length
			console.log _stats
			assert.eql ( count - 10000 + 100 ), _keys.length

			assert.equal( n, count )
			return
		return
			

	"delete": (beforeExit, assert) ->
		console.log "\nSTART DELETE TEST"
		n = 0
		count = 10000
		startKeys = localCache.getStats().keys
		
		# test deletes
		for i in [1..count]
			ri = Math.floor(Math.random() * vs.length)
			localCache.del ks[ i ], ( err, count )->
				n++
				assert.isNull( err, err )
				assert.equal( 1, count )
		
		# test deletes again. should not delete a key
		for i in [1..count]
			ri = Math.floor(Math.random() * vs.length)
			localCache.del ks[ i ], ( err, count )->
				n++
				assert.equal( 0, count )
				assert.isNull( err, err )
		
		# check stats for only a single deletion	
		assert.equal( localCache.getStats().keys, startKeys - count )
		
		beforeExit ->
			# check  successfull runs
			assert.equal( n, count * 2)
			return
		return
	
	"stats": (beforeExit, assert) ->
		console.log "\nSTART STATS TEST"
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
				return
		
		# get and remove `count` elements 
		for i in [1..count]
			localCache.get keys[ i ], ( err, res )->
				n++
				assert.eql( vals[ i ], res )
				assert.isNull( err, err )
				return

			localCache.del keys[ i ], ( err, success )->
				n++
				assert.isNull( err, err )
				assert.ok( success )
				return
		
		# generate `count` misses
		for i in [1..count]
			# 4 char key should not exist
			localCache.get "xxxx", ( err, res )->
				++n
				assert.isNull( err, err )
				assert.isUndefined( res, res )
				return

		end = localCache.getStats()
		
		# check predicted stats
		assert.equal( end.hits - start.hits, 5, "hits wrong" )
		assert.equal( end.misses - start.misses, 5, "misses wrong" )
		assert.equal( end.keys - start.keys, 5, "hits wrong" )
		assert.equal( end.ksize - start.ksize, 5*7, "hits wrong" )
		assert.equal( end.vsize - start.vsize, 5*50, "hits wrong" )
		
		beforeExit ->

			assert.equal( n, count*5 )
			return

		return
	
	"multi": (beforeExit, assert) ->
		console.log "\nSTART MULTI TEST"
		n = 0
		count = 100
		startKeys = localCache.getStats().keys

		# set `count` values
		ks = []
		val = randomString( 20 )
		for i in [1..count]
			key = randomString( 7 )
			ks.push key
		
		for key in ks
			localCache.set key, val, 0, ( err, res )->
				n++
				assert.isNull( err, err )
				return
		
		# generate a sub list of keys
		getKeys = ks.splice( 50, 5 )
		# generate prediction
		pred = {}
		for key in getKeys
			pred[ key ] = val
		
		# try to get list
		localCache.mget getKeys[ 0 ], ( err, res )->
			n++
			assert.isNotNull( err, err )
			assert.eql( err.constructor.name, "Error" )
			assert.eql "EKEYSTYPE", err.name
			assert.isUndefined( res, res )
			return

		# try to get list
		localCache.mget getKeys, ( err, res )->
			n++
			assert.isNull( err, err )
			assert.eql( pred, res )
			return
		
		# delete list of keys
		localCache.del getKeys, ( err, res )->
			n++
			assert.isNull( err, err )
			assert.equal( getKeys.length, res )
			return
		
		# try to get list again. Empty result predicted
		localCache.mget getKeys, ( err, res )->
			n++
			assert.isNull( err, err )
			assert.eql( {}, res )
			return
		
		beforeExit ->
			# check  successfull runs
			assert.equal( n, count + 4)
			return
		return
	
	"ttl": (beforeExit, assert) ->
		console.log "\nSTART TTL TEST"

		val = randomString( 20 )
		key = "k1_" + randomString( 7 )
		key2 = "k2_" + randomString( 7 )
		key3 = "k3_" + randomString( 7 )
		key4 = "k4_" + randomString( 7 )
		key5 = "k5_" + randomString( 7 )
		_keys = [ key, key2, key3, key4, key5 ]
		n = 0

		# set a key with ttl
		localCache.set key, val, 0.5, ( err, res )->
			assert.isNull( err, err )
			assert.ok( res )

			# check the key immediately
			localCache.get key, ( err, res )->
				assert.isNull( err, err )
				assert.eql( val, res )
				return
			return
		
		# set another key
		localCache.set key2, val, 0.3, ( err, res )->
			assert.isNull( err, err )
			assert.ok( res )

			# check the key immediately
			localCache.get key2, ( err, res )->
				assert.isNull( err, err )
				assert.eql( val, res )
				return
			return

		# check key before lifetime end
		setTimeout( ->
			++n
			localCache.get key, ( err, res )->
				assert.isNull( err, err )
				assert.eql( val, res )
				return
			return
		, 400 )

		# check key after lifetime end
		setTimeout( ->
			++n
			localCache.get key, ( err, res )->
				assert.isNull( err, err )
				assert.isUndefined( res, res )
				return
			return
		, 600 )

		# check second key before lifetime end
		setTimeout( ->
			++n
			localCache.get key2, ( err, res )->
				assert.isNull( err, err )
				assert.eql( val, res )
				return
			return
		, 250 )

		# test the automatic check
		setTimeout( ->
			process.nextTick ->
				startKeys = localCache.getStats().keys

				key = "autotest"

				_testExpired = ( _key, _val )->
					if _key not in _keys
						assert.equal( _key, key )
						assert.equal( _val, val )
					return

				_testSet = ( _key )->
					assert.equal( _key, key )
					return

				localCache.once "set", _testSet

				# inset a value with ttl
				localCache.set key, val, 0.5, ( err, res )->
					assert.isNull( err, err )
					assert.ok( res )
					assert.equal( startKeys + 1, localCache.getStats().keys )

					# check existens
					localCache.get key, ( err, res )->
						assert.eql( val, res )
							
						localCache.on "expired", _testExpired

						# run general checkdata after ttl
						setTimeout( ->
							localCache._checkData( false )
							
							# deep dirty check if key is deleted
							assert.isUndefined( localCache.data[ key ] )

							localCache.removeAllListeners( "set" )
							localCache.removeAllListeners( "expired" )
							return
						, 700 )
					return
				return
			return
		, 1000 )

		# set a key with ttl
		localCache.set key3, val, 100, ( err, res )->
			assert.isNull( err, err )
			assert.ok( res )

			# check the key3 immediately
			localCache.get key3, ( err, res )->
				assert.isNull( err, err )
				assert.eql( val, res )

				# check ttl with false key
				localCache.ttl ( key3 + "false" ), 0.3, ( err, setted )->
					assert.isNull( err, err )
					assert.equal(false, setted)
					return

					# check ttl with false key
				localCache.ttl key3, 0.3, ( err, setted )->
					assert.isNull( err, err )
					assert.ok(setted)
					return

				# check existens
				localCache.get key3, ( err, res )->
					assert.eql( val, res )
					return

				# run general checkdata after ttl
				setTimeout( ->
					# check existens
					res = localCache.get( key3 )
					assert.isUndefined( res, res )

					#localCache._checkData( false )
					
					# deep dirty check if key is deleted
					assert.isUndefined( localCache.data[ key3 ] )
					return

				, 500 )
				return
			return
		

		# set a key with default ttl = 0
		localCache.set key4, val, 100, ( err, res )->
			assert.isNull( err, err )
			assert.ok( res )

			# check the key4 immediately
			localCache.get key4, ( err, res )->
				assert.isNull( err, err )
				assert.eql( val, res )

				# check ttl with false key
				localCache.ttl ( key4 + "false" ), ( err, setted )->
					assert.isNull( err, err )
					assert.equal(false, setted)

					# check ttl with false key
				localCache.ttl key4, ( err, setted )->
					assert.isNull( err, err )
					assert.ok(setted)

					# deep dirty check if key is deleted
					assert.isUndefined( localCache.data[ key4 ] )
					return
				return
			return

		# set a key with default ttl
		localCacheTTL.set key5, val, 100, ( err, res )->
			assert.isNull( err, err )
			assert.ok( res )

			# check the key5 immediately
			localCacheTTL.get key5, ( err, res )->
				assert.isNull( err, err )
				assert.eql( val, res )

				# check ttl with false key
				localCacheTTL.ttl ( key5 + "false" ), ( err, setted )->
					assert.isNull( err, err )
					assert.equal(false, setted)
					return

					# check ttl with false key
				localCacheTTL.ttl key5, ( err, setted )->
					assert.isNull( err, err )
					assert.ok(setted)
					return

				# check existens
				localCacheTTL.get key5, ( err, res )->
					assert.eql( val, res )
					return

				# run general checkdata after ttl
				setTimeout( ->
					# check existens
					res = localCache.get( key5 )
					assert.isUndefined( res, res )
					
					localCacheTTL._checkData( false )
					
					# deep dirty check if key is deleted
					assert.isUndefined( localCacheTTL.data[ key5 ] )
					return
				, 500 )
				return
			return
		return
