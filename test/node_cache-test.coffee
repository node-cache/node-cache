# define runtime environment
_ = require( "underscore" )

VCache = require "../lib/node_cache"
localCache = new VCache( stdTTL: 0 )
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
		console.log "\nSTART GENERAL TEST"

		n = 0

		start = _.clone( localCache.getStats() )
		
		value = randomString( 100 )
		value2 = randomString( 100 )
		key = randomString( 10 )


		localCache.once "del", ( _key )->
			assert.equal( _key, key )
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
				assert.equal( 0, res )
			
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
					assert.eql {}, res

			# set a key with 0
			localCache.set "zero", 0, 0, ( err, res )->
				n++
				assert.isNull( err, err )
				assert.ok( res, err )

			# get a key with 0
			localCache.get "zero", ( err, res )->
				n++
				assert.isNull( err, err )
				assert.eql { "zero": 0 }, res

		beforeExit ->
			assert.equal( 10, n, "not exited" )

	"general sync": (beforeExit, assert) ->
		console.log "\nSTART GENERAL TEST SYNC"

		n = 0

		start = _.clone( localCache.getStats() )
		
		value = randomString( 100 )
		value2 = randomString( 100 )
		key = randomString( 10 )

		localCache.once "del", ( _key )->
			assert.equal( _key, key )
			return

		# test insert
		assert.ok localCache.set( key, value, 0 )
		n++

		# check stats
		assert.equal 1, localCache.getStats().keys - start.keys

		# try to get
		res = localCache.get( key )
		n++
		# generate a predicted value
		pred = {}
		pred[ key ] = value
		assert.eql pred, res

		# get an undefined key
		res = localCache.get( "xxx" )
		n++
		assert.eql {}, res

		# try to delete an undefined key
		res = localCache.del( "xxx" )
		n++
		assert.equal( 0, res )
		
		# test update
		res = localCache.set( key, value2, 0 )
		n++
		assert.ok( res, res )
			
		# check update
		res = localCache.get( key )
		n++
		# generate a predicted value
		pred = {}
		pred[ key ] = value2
		assert.eql pred, res

		# check if stats didn't changed
		assert.equal 1, localCache.getStats().keys - start.keys

		# try to delete the defined key
		res = localCache.del( key )
		localCache.removeAllListeners( "del" )
		n++
		assert.equal 1, res

		# check stats
		assert.equal 0, localCache.getStats().keys - start.keys

		# try to get the deleted key
		res = localCache.get( key )
		n++
		assert.eql {}, res

		# set a key with 0
		res = localCache.set( "zero", 0, 0 )
		n++
		assert.ok( res, res )

		# get a key with 0
		res = localCache.get( "zero" )
		n++
		assert.eql { "zero": 0 }, res

		beforeExit ->
			assert.equal( 10, n, "not exited" )
	
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
			pred = {}
			pred[ key ] = val
			_res = localCache.get( key )
			assert.eql pred, _res
		
		_dur = new Date().getTime() - time
		console.log( "BENCHMARK for GET:", "#{_dur}ms", " ( #{_dur/count}ms per item ) " )
		console.log( "BENCHMARK STATS:", localCache.getStats() )
		
		beforeExit ->
			assert.equal( n, count )
			

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
		localCache.get getKeys, ( err, res )->
			n++
			assert.isNull( err, err )
			assert.eql( pred, res )
		
		# delete list of keys
		localCache.del getKeys, ( err, res )->
			n++
			assert.isNull( err, err )
			assert.equal( getKeys.length, res )
		
		# try to get list again. Empty result predicted
		localCache.get getKeys, ( err, res )->
			n++
			assert.isNull( err, err )
			assert.eql( {}, res )
		
		beforeExit ->
			# check  successfull runs
			assert.equal( n, count + 3)
	
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
				pred = {}
				pred[ key ] = val
				assert.eql( pred, res )
		
		# set another key
		localCache.set key2, val, 0.3, ( err, res )->
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
		, 250 )

		# test the automatic check
		setTimeout( ->
			process.nextTick ->
				startKeys = localCache.getStats().keys

				key = "autotest"

				_testExpired = ( _key, _val )=>
					if _key not in _keys
						assert.equal( _key, key )
						assert.equal( _val, val )
					return

				_testSet = ( _key )=>
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
						pred = {}
						pred[ key ] = val
						assert.eql( pred, res )
							
						localCache.on "expired", _testExpired

						# run general checkdata after ttl
						setTimeout( ->
							localCache._checkData( false )
							
							# deep dirty check if key is deleted
							assert.isUndefined( localCache.data[ key ] )

							localCache.removeAllListeners( "set" )
							localCache.removeAllListeners( "expired" )

						, 700 )

		, 1000 )

		# set a key with ttl
		localCache.set key3, val, 100, ( err, res )->
			assert.isNull( err, err )
			assert.ok( res )

			# check the key3 immediately
			localCache.get key3, ( err, res )->
				assert.isNull( err, err )
				pred = {}
				pred[ key3 ] = val
				assert.eql( pred, res )

				# check ttl with false key
				localCache.ttl ( key3 + "false" ), 0.3, ( err, setted )->
					assert.isNull( err, err )
					assert.equal(false, setted)

					# check ttl with false key
				localCache.ttl key3, 0.3, ( err, setted )->
					assert.isNull( err, err )
					assert.ok(setted)

				# check existens
				localCache.get key3, ( err, res )->
					pred = {}
					pred[ key3 ] = val
					assert.eql( pred, res )

				# run general checkdata after ttl
				setTimeout( ->
					# check existens
					assert.eql( localCache.get( key3 ), {} )

					#localCache._checkData( false )
					
					# deep dirty check if key is deleted
					assert.isUndefined( localCache.data[ key3 ] )
					return

				, 500 )
		

		# set a key with default ttl = 0
		localCache.set key4, val, 100, ( err, res )->
			assert.isNull( err, err )
			assert.ok( res )

			# check the key4 immediately
			localCache.get key4, ( err, res )->
				assert.isNull( err, err )
				pred = {}
				pred[ key4 ] = val
				assert.eql( pred, res )

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

		# set a key with default ttl
		localCacheTTL.set key5, val, 100, ( err, res )->
			assert.isNull( err, err )
			assert.ok( res )

			# check the key5 immediately
			localCacheTTL.get key5, ( err, res )->
				assert.isNull( err, err )
				pred = {}
				pred[ key5 ] = val
				assert.eql( pred, res )

				# check ttl with false key
				localCacheTTL.ttl ( key5 + "false" ), ( err, setted )->
					assert.isNull( err, err )
					assert.equal(false, setted)

					# check ttl with false key
				localCacheTTL.ttl key5, ( err, setted )->
					assert.isNull( err, err )
					assert.ok(setted)

				# check existens
				localCacheTTL.get key5, ( err, res )->
					pred = {}
					pred[ key5 ] = val
					assert.eql( pred, res )

				# run general checkdata after ttl
				setTimeout( ->
					# check existens
					assert.eql( localCache.get( key5 ), {} )

					localCacheTTL._checkData( false )
					
					# deep dirty check if key is deleted
					assert.isUndefined( localCacheTTL.data[ key5 ] )
					
				, 500 )




		
	
