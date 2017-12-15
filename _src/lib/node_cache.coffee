# lodash requires
_assignIn = require( "lodash/assignIn" )
_isArray = require( "lodash/isArray" )
_isString = require( "lodash/isString" )
_isFunction = require( "lodash/isFunction" )
_isNumber = require( "lodash/isNumber" )
_isObject = require( "lodash/isObject" )
_size = require( "lodash/size" )
_template = require( "lodash/template" )

clone = require( "clone" )
EventEmitter = require('events').EventEmitter

# generate superclass
module.exports = class NodeCache extends EventEmitter
	constructor: ( @options = {} )->

		@_initErrors()
		# container for cached data
		@data = {}

		# module options
		@options = _assignIn(
			# convert all elements to string
			forceString: false
			# used standard size for calculating value size
			objectValueSize: 80
			arrayValueSize: 40
			# standard time to live in seconds. 0 = infinity;
			stdTTL: 0
			# time in seconds to check all data and delete expired keys
			checkperiod: 600
			# en/disable cloning of variables. If `true` you'll get a copy of the cached variable. If `false` you'll save and get just the reference
			useClones: true
			# en/disable throwing errors when trying to `.get` missing or expired values.
			errorOnMissing: false
			# whether values should be deleted automatically at expiration
			deleteOnExpire: true
		, @options )

		# statistics container
		@stats =
			hits: 0
			misses: 0
			keys: 0
			ksize: 0
			vsize: 0

		# pre allocate valid keytypes array
		@validKeyTypes = ["string", "number"]

		# initalize checking period
		@_checkData()
		return

	# ## get
	#
	# get a cached key and change the stats
	#
	# **Parameters:**
	#
	# * `key` ( String | Number ): cache key
	# * `[cb]` ( Function ): Callback function
	# * `[errorOnMissing=false]` ( Boolean ) return a error to the `cb` or throw it if no `cb` is used. Otherwise the get will return `undefined` on a miss.
	#
	# **Example:**
	#
	#     myCache.get "myKey", ( err, val )->
	#       console.log( err, val )
	#       return
	#
	get: ( key, cb, errorOnMissing )=>
		# handle passing in errorOnMissing without cb
		if typeof cb == "boolean" and arguments.length == 2
			errorOnMissing = cb
			cb = undefined

		# handle invalid key types
		if (err = @_isInvalidKey( key ))?
			if cb?
				cb( err )
				return
			else
				throw err

		# get data and incremet stats
		if @data[ key ]? and @_check( key, @data[ key ] )
			@stats.hits++
			_ret = @_unwrap( @data[ key ] )
			# return data
			cb( null, _ret ) if cb?
			return _ret
		else
			# if not found return a error
			@stats.misses++
			if @options.errorOnMissing or errorOnMissing
				_err = @_error( "ENOTFOUND", { key: key }, cb )
				if _err?
					throw _err
				return
			else
				cb( null, undefined ) if cb?
			return undefined


	# ## mget
	#
	# get multiple cached keys at once and change the stats
	#
	# **Parameters:**
	#
	# * `keys` ( String|Number[] ): an array of keys
	# * `[cb]` ( Function ): Callback function
	#
	# **Example:**
	#
	#     myCache.mget [ "foo", "bar" ], ( err, val )->
	#       console.log( err, val )
	#       return
	#
	mget: ( keys, cb )=>
		# convert a string to an array of one key
		if not _isArray( keys )
			_err = @_error( "EKEYSTYPE" )
			cb( _err ) if cb?
			return _err

		# define return
		oRet = {}
		for key in keys
			# handle invalid key types
			if (err = @_isInvalidKey( key ))?
				if cb?
					cb( err )
					return
				else
					throw err

			# get data and increment stats
			if @data[ key ]? and @_check( key, @data[ key ] )
				@stats.hits++
				oRet[ key ] = @_unwrap( @data[ key ] )
			else
				# if not found return a error
				@stats.misses++

		# return all found keys
		cb( null, oRet ) if cb?
		return oRet

	# ## set
	#
	# set a cached key and change the stats
	#
	# **Parameters:**
	#
	# * `key` ( String | Number ): cache key
	# * `value` ( Any ): A element to cache. If the option `option.forceString` is `true` the module trys to translate it to a serialized JSON
	# * `[ ttl ]` ( Number | String ): ( optional ) The time to live in seconds.
	# * `[cb]` ( Function ): Callback function
	#
	# **Example:**
	#
	#     myCache.set "myKey", "my_String Value", ( err, success )->
	#       console.log( err, success )
	#
	#     myCache.set "myKey", "my_String Value", "10", ( err, success )->
	#       console.log( err, success )
	#
	set: ( key, value, ttl, cb )=>
		# force the data to string
		if @options.forceString and not _isString( value )
			value = JSON.stringify( value )

		# remap the arguments if `ttl` is not passed
		if arguments.length is 3 and _isFunction( ttl )
			cb = ttl
			ttl = @options.stdTTL

		# handle invalid key types
		if (err = @_isInvalidKey( key ))?
			if cb?
				cb( err )
				return
			else
				throw err

		# internal helper variables
		existent = false

		# remove existing data from stats
		if @data[ key ]
			existent = true
			@stats.vsize -= @_getValLength( @_unwrap( @data[ key ], false ) )

		# set the value
		@data[ key ] = @_wrap( value, ttl )
		@stats.vsize += @_getValLength( value )

		# only add the keys and key-size if the key is new
		if not existent
			@stats.ksize += @_getKeyLength( key )
			@stats.keys++

		@emit( "set", key, value )

		# return true
		cb( null, true ) if cb?
		return true

	# ## del
	#
	# remove keys
	#
	# **Parameters:**
	#
	# * `keys` ( String | Number | String|Number[] ): cache key to delete or a array of cache keys
	# * `[cb]` ( Function ): Callback function
	#
	# **Return**
	#
	# ( Number ): Number of deleted keys
	#
	# **Example:**
	#
	#     myCache.del( "myKey" )
	#
	#     myCache.del( "myKey", ( err, delCount )->
	#       console.log( err, delCount )
	#       return
	del: ( keys, cb )=>
		# convert keys to an array of itself
		if not _isArray( keys )
			keys = [ keys ]

		delCount = 0
		for key in keys
			# handle invalid key types
			if (err = @_isInvalidKey( key ))?
				if cb?
					cb( err )
					return
				else
					throw err
			# only delete if existent
			if @data[ key ]?
				# calc the stats
				@stats.vsize -= @_getValLength( @_unwrap( @data[ key ], false ) )
				@stats.ksize -= @_getKeyLength( key )
				@stats.keys--
				delCount++
				# delete the value
				oldVal = @data[ key ]
				delete @data[ key ]
				# return true
				@emit( "del", key, oldVal.v )
			else
				# if the key has not been found return an error
				@stats.misses++


		cb( null, delCount ) if cb?
		return delCount

	# ## ttl
	#
	# reset or redefine the ttl of a key. `ttl` = 0 means inifite lifetime.
	# If `ttl` is not passed the default ttl is used.
	# If `ttl` < 0 the key will be deleted.
	#
	# **Parameters:**
	#
	# * `key` ( String | Number ): cache key to reset the ttl value
	# * `ttl` ( Number ): ( optional -> options.stdTTL || 0 ) The time to live in seconds
	# * `[cb]` ( Function ): Callback function
	#
	# **Return**
	#
	# ( Boolen ): key found and ttl set
	#
	# **Example:**
	#
	#     myCache.ttl( "myKey" ) // will set ttl to default ttl
	#
	#     myCache.ttl( "myKey", 1000, ( err, keyFound )->
	#       console.log( err, success )
	#
	ttl: =>
		# change args if only key and callback are passed
		[ key, args... ] = arguments
		for arg in args
			switch typeof arg
				when "number" then ttl = arg
				when "function" then cb = arg

		ttl or= @options.stdTTL
		if not key
			cb( null, false ) if cb?
			return false

		# handle invalid key types
		if (err = @_isInvalidKey( key ))?
			if cb?
				cb( err )
				return
			else
				throw err

		# check for existent data and update the ttl value
		if @data[ key ]? and @_check( key, @data[ key ] )
			# if ttl < 0  delete the key. otherwise reset the value
			if ttl >= 0
				@data[ key ] = @_wrap( @data[ key ].v, ttl, false )
			else
				@del( key )
			cb( null, true ) if cb?
			return true
		else
			# return false if key has not been found
			cb( null, false ) if cb?
			return false

		return

	# ## getTtl
	#
	# receive the ttl of a key.
	#
	# **Parameters:**
	#
	# * `key` ( String | Number ): cache key to check the ttl value
	# * `[cb]` ( Function ): Callback function
	#
	# **Return**
	#
	# ( Number|undefined ): The timestamp in ms when the key will expire, 0 if it will never expire or undefined if it not exists
	#
	# **Example:**
	#
	#     ts = myCache.getTtl( "myKey" )
	#
	#     myCache.getTtl( "myKey",( err, ttl )->
	#       console.log( err, ttl )
	#       return
	#
	getTtl: ( key, cb )=>
		if not key
			cb( null, undefined ) if cb?
			return undefined

		# handle invalid key types
		if (err = @_isInvalidKey( key ))?
			if cb?
				cb( err )
				return
			else
				throw err

		# check for existent data and update the ttl value
		if @data[ key ]? and @_check( key, @data[ key ] )
			_ttl = @data[ key ].t
			cb( null, _ttl ) if cb?
			return _ttl
		else
			# return undefined if key has not been found
			cb( null, undefined ) if cb?
			return undefined

		return

	# ## getTs
	#
	# receive the timestamp of a key.
	#
	# **Parameters:**
	#
	# * `key` ( String | Number ): cache key to check the ts value
	# * `[cb]` ( Function ): Callback function
	#
	# **Return**
	#
	# ( Number|undefined ): The timestamp in ms when the key was set or undefined if it does not exist
	#
	# **Example:**
	#
	#     ts = myCache.getTs( "myKey" )
	#
	#     myCache.getTs( "myKey",( err, ts )->
	#       console.log( err, ts )
	#       return
	#
	getTs: ( key, cb )=>
		if not key
			cb( null, undefined ) if cb?
			return undefined

		# handle invalid key types
		if (err = @_isInvalidKey( key ))?
			if cb?
				cb( err )
				return
			else
				throw err

		# check for existent data and update the ttl value
		if @data[ key ]? and @_check( key, @data[ key ] )
			_ts = @data[ key ].ts
			cb( null, _ts ) if cb?
			return _ts
		else
	# return undefined if key has not been found
			cb( null, undefined ) if cb?
			return undefined

		return

	# ## keys
	#
	# list all keys within this cache
	#
	# **Parameters:**
	#
	# * `[cb]` ( Function ): Callback function
	#
	# **Return**
	#
	# ( Array ): An array of all keys
	#
	# **Example:**
	#
	#     _keys = myCache.keys()
	#
	#     # [ "foo", "bar", "fizz", "buzz", "anotherKeys" ]
	#
	keys: ( cb )=>
		_keys = Object.keys( @data )
		cb( null, _keys )if cb?
		return _keys

	# ## getStats
	#
	# get the stats
	#
	# **Parameters:**
	#
	# -
	#
	# **Return**
	#
	# ( Object ): Stats data
	#
	# **Example:**
	#
	#     myCache.getStats()
	#     # {
	#     # hits: 0,
	#     # misses: 0,
	#     # keys: 0,
	#     # ksize: 0,
	#     # vsize: 0
	#     # }
	#
	getStats: =>
		@stats

	# ## flushAll
	#
	# flush the hole data and reset the stats
	#
	# **Example:**
	#
	#     myCache.flushAll()
	#
	#     myCache.getStats()
	#     # {
	#     # hits: 0,
	#     # misses: 0,
	#     # keys: 0,
	#     # ksize: 0,
	#     # vsize: 0
	#     # }
	#
	flushAll: ( _startPeriod = true )=>
		# parameter just for testing

		# set data empty
		@data = {}

		# reset stats
		@stats =
			hits: 0
			misses: 0
			keys: 0
			ksize: 0
			vsize: 0

		# reset check period
		@_killCheckPeriod()
		@_checkData( _startPeriod )

		@emit( "flush" )

		return

	# ## close
	#
	# This will clear the interval timeout which is set on checkperiod option.
	#
	# **Example:**
	#
	#     myCache.close()
	#
	close: =>
		@_killCheckPeriod()
		return

	# ## _checkData
	#
	# internal Housekeeping mehtod.
	# Check all the cached data and delete the invalid values
	_checkData: ( startPeriod = true )=>
		# run the housekeeping method
		for key, value of @data
			@_check( key, value )

		if startPeriod and @options.checkperiod > 0
			@checkTimeout = setTimeout( @_checkData, ( @options.checkperiod * 1000 ), startPeriod )
			@checkTimeout.unref() if @checkTimeout.unref?
		return

	# ## _killCheckPeriod
	#
	# stop the checkdata period. Only needed to abort the script in testing mode.
	_killCheckPeriod: ->
		clearTimeout( @checkTimeout ) if @checkTimeout?

	# ## _check
	#
	# internal method the check the value. If it's not valid any more delete it
	_check: ( key, data )=>
		_retval = true
		# data is invalid if the ttl is to old and is not 0
		#console.log data.t < Date.now(), data.t, Date.now()
		if data.t isnt 0 and data.t < Date.now()
			if @options.deleteOnExpire
				_retval = false;
				@del( key )
			@emit( "expired", key, @_unwrap(data) )

		return _retval

	# ## _isInvalidKey
	#
	# internal method to check if the type of a key is either `number` or `string`
	_isInvalidKey: ( key )=>
		unless typeof key in @validKeyTypes
			return @_error( "EKEYTYPE", { type: typeof key })
		return


	# ## _wrap
	#
	# internal method to wrap a value in an object with some metadata
	_wrap: ( value, ttl, asClone = true )=>
		if not @options.useClones
			asClone = false
		# define the time to live
		now = Date.now()
		livetime = 0

		ttlMultiplicator = 1000

		# use given ttl
		if ttl is 0
			livetime = 0
		else if ttl
			livetime = now + ( ttl * ttlMultiplicator )
		else
			# use standard ttl
			if @options.stdTTL is 0
				livetime = @options.stdTTL
			else
				livetime = now + ( @options.stdTTL * ttlMultiplicator )

		# return the wrapped value
		oReturn =
			t: livetime
			ts: now
			v: if asClone then clone( value ) else value

	# ## _unwrap
	#
	# internal method to extract get the value out of the wrapped value
	_unwrap: ( value, asClone = true )->
		if not @options.useClones
			asClone = false
		if value.v?
			if asClone
				return clone( value.v )
			else
				return value.v
		return null

	# ## _getKeyLength
	#
	# internal method the calculate the key length
	_getKeyLength: ( key )->
		key.length

	# ## _getValLength
	#
	# internal method to calculate the value length
	_getValLength: ( value )=>
		if _isString( value )
			# if the value is a String get the real length
			value.length
		else if @options.forceString
			# force string if it's defined and not passed
			JSON.stringify( value ).length
		else if _isArray( value )
			# if the data is an Array multiply each element with a defined default length
			@options.arrayValueSize * value.length
		else if _isNumber( value )
			8
		else if _isObject( value )
			# if the data is an Object multiply each element with a defined default length
			@options.objectValueSize * _size( value )
		else
			# default fallback
			0

	# ## _error
	#
	# internal method to handle an error message
	_error: ( type, data = {}, cb )=>
		# generate the error object
		error = new Error()
		error.name = type
		error.errorcode = type
		error.message = if @ERRORS[ type ]? then @ERRORS[ type ]( data ) else "-"
		error.data = data

		if cb and _isFunction( cb )
			# return the error
			cb( error, null )
			return
		else
			# if no callback is defined return the error object
			return error

	# ## _initErrors
	#
	# internal method to generate error message templates
	_initErrors: =>
		@ERRORS = {}
		for _errT, _errMsg of @_ERRORS
			@ERRORS[ _errT ] = _template( _errMsg )

		return

	_ERRORS:
		"ENOTFOUND": "Key `<%= key %>` not found"
		"EKEYTYPE": "The key argument has to be of type `string` or `number`. Found: `<%= type %>`"
		"EKEYSTYPE": "The keys argument has to be an array."
