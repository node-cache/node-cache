clone = require( "clone" )
EventEmitter = require('events').EventEmitter

# generate superclass
module.exports = class NodeCache extends EventEmitter
	constructor: ( @options = {} )->
		super()

		@_initErrors()

		# container for cached data
		@data = {}

		# module options
		@options = Object.assign(
			# convert all elements to string
			forceString: false
			# used standard size for calculating value size
			objectValueSize: 80
			promiseValueSize: 80
			arrayValueSize: 40
			# standard time to live in seconds. 0 = infinity;
			stdTTL: 0
			# time in seconds to check all data and delete expired keys
			checkperiod: 600
			# en/disable cloning of variables. If `true` you'll get a copy of the cached variable. If `false` you'll save and get just the reference
			useClones: true
			# whether values should be deleted automatically at expiration
			deleteOnExpire: true
			# enable legacy callbacks
			enableLegacyCallbacks: false
			# max amount of keys that are being stored
			maxKeys: -1
		, @options )

		# generate functions with callbacks (legacy)
		if (@options.enableLegacyCallbacks)
			console.warn("WARNING! node-cache legacy callback support will drop in v6.x")
			[
				"get",
				"mget",
				"set",
				"del",
				"ttl",
				"getTtl",
				"keys",
				"has"
			].forEach((methodKey) =>
				# reference real function
				oldMethod = @[methodKey]
				@[methodKey] = (args..., cb) ->
					# return a callback if cb is defined and a function
					if (typeof cb is "function")
						try
							res = oldMethod(args...)
							cb(null, res)
						catch err
							cb(err)
					else
						return oldMethod(args..., cb)
					return
				return
			)

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
	#
	# **Example:**
	#
	#	myCache.get "myKey", ( err, val )
	#
	get: ( key )=>
		# handle invalid key types
		if (err = @_isInvalidKey( key ))?
			throw err

		# get data and increment stats
		if @data[ key ]? and @_check( key, @data[ key ] )
			@stats.hits++
			_ret = @_unwrap( @data[ key ] )
			# return data
			return _ret
		else
			# if not found return undefined
			@stats.misses++
			return undefined

	# ## mget
	#
	# get multiple cached keys at once and change the stats
	#
	# **Parameters:**
	#
	# * `keys` ( String|Number[] ): an array of keys
	#
	# **Example:**
	#
	#	myCache.mget [ "foo", "bar" ]
	#
	mget: ( keys )=>
		# convert a string to an array of one key
		if not Array.isArray( keys )
			_err = @_error( "EKEYSTYPE" )
			throw _err

		# define return
		oRet = {}
		for key in keys
			# handle invalid key types
			if (err = @_isInvalidKey( key ))?
				throw err

			# get data and increment stats
			if @data[ key ]? and @_check( key, @data[ key ] )
				@stats.hits++
				oRet[ key ] = @_unwrap( @data[ key ] )
			else
				# if not found return a error
				@stats.misses++

		# return all found keys
		return oRet

	# ## set
	#
	# set a cached key and change the stats
	#
	# **Parameters:**
	#
	# * `key` ( String | Number ): cache key
	# * `value` ( Any ): An element to cache. If the option `option.forceString` is `true` the module trys to translate it to a serialized JSON
	# * `[ ttl ]` ( Number | String ): ( optional ) The time to live in seconds.
	#
	# **Example:**
	#
	#	myCache.set "myKey", "my_String Value"
	#
	#	myCache.set "myKey", "my_String Value", 10
	#
	set: ( key, value, ttl )=>
		# check if cache is overflowing
		if (@options.maxKeys > -1 && @stats.keys >= @options.maxKeys)
			_err = @_error( "ECACHEFULL" )
			throw _err

		# force the data to string
		if @options.forceString and typeof value isnt "string"
			value = JSON.stringify( value )

		# set default ttl if not passed
		unless ttl?
			ttl = @options.stdTTL

		# handle invalid key types
		if (err = @_isInvalidKey( key ))?
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
		return true
	
	# ## fetch
	#
	# in the event of a cache miss (no value is assinged to given cache key), value will be written to cache and returned. In case of cache hit, cached value will be returned without executing given value. If the given value is type of `Function`, it will be executed and returned result will be fetched
	#
	# **Parameters:**
	#
	# * `key` ( String | Number ): cache key
	# * `[ ttl ]` ( Number | String ): ( optional ) The time to live in seconds.
	# * `value` ( Any ): if `Function` type is given, it will be executed and returned value will be fetched, otherwise the value itself is fetched
	#
	# **Example:**
	#
	# myCache.fetch "myKey", 10, () => "my_String value"
	#
	# myCache.fetch "myKey", "my_String value"
	#
	fetch: ( key, ttl, value )=>
		# check if cache is hit
		if @has( key )
			return @get( key )
		if typeof value == 'undefined'
			value = ttl
			ttl = undefined
		_ret = if typeof value == 'function' then value() else value
		@set( key, _ret, ttl )
		return _ret

	# ## mset
	#
	# set multiple keys at once
	#
	# **Parameters:**
	#
	# * `keyValueSet` ( Object[] ): an array of objects which include key, value, and ttl
	#
	# **Example:**
	#
	#	myCache.mset(
	#		[
	#			{
	#				key: "myKey",
	#				val: "myValue",
	#				ttl: [ttl in seconds]
	#			}
	#		])
	#
	#
	
	mset: ( keyValueSet ) =>
		# check if cache is overflowing
		if (@options.maxKeys > -1 && @stats.keys + keyValueSet.length >= @options.maxKeys)
			_err = @_error( "ECACHEFULL" )
			throw _err
		
		# loop over keyValueSet to validate key and ttl

		for keyValuePair in keyValueSet
			{ key, val, ttl } = keyValuePair

			# check if there is ttl and it's a number
			if ttl and typeof ttl isnt "number"
				_err = @_error( "ETTLTYPE" )
				throw _err


			# handle invalid key types
			if (err = @_isInvalidKey( key ))?
				throw err

		for keyValuePair in keyValueSet
			{ key, val, ttl } = keyValuePair
			@set(key, val, ttl)
		return true

	# ## del
	#
	# remove keys
	#
	# **Parameters:**
	#
	# * `keys` ( String | Number | String|Number[] ): cache key to delete or an array of cache keys
	#
	# **Return**
	#
	# ( Number ): Number of deleted keys
	#
	# **Example:**
	#
	#	myCache.del( "myKey" )
	#
	del: ( keys )=>
		# convert keys to an array of itself
		if not Array.isArray( keys )
			keys = [ keys ]

		delCount = 0
		for key in keys
			# handle invalid key types
			if (err = @_isInvalidKey( key ))?
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


		return delCount

	# ## take
	#
	# get the cached value and remove the key from the cache.
	# Equivalent to calling `get(key)` + `del(key)`.
	# Useful for implementing `single use` mechanism such as OTP, where once a value is read it will become obsolete.
	#
	# **Parameters:**
	#
	# * `key` ( String | Number ): cache key
	#
	# **Example:**
	#
	#	myCache.take "myKey", ( err, val )
	#
	take: ( key )=>
		_ret = @get(key)
		if (_ret?)
			@del(key)
		return _ret

	# ## ttl
	#
	# reset or redefine the ttl of a key. `ttl` = 0 means infinite lifetime.
	# If `ttl` is not passed the default ttl is used.
	# If `ttl` < 0 the key will be deleted.
	#
	# **Parameters:**
	#
	# * `key` ( String | Number ): cache key to reset the ttl value
	# * `ttl` ( Number ): ( optional -> options.stdTTL || 0 ) The time to live in seconds
	#
	# **Return**
	#
	# ( Boolen ): key found and ttl set
	#
	# **Example:**
	#
	#	myCache.ttl( "myKey" ) // will set ttl to default ttl
	#
	#	myCache.ttl( "myKey", 1000 )
	#
	ttl: (key, ttl) =>
		ttl or= @options.stdTTL
		if not key
			return false

		# handle invalid key types
		if (err = @_isInvalidKey( key ))?
			throw err

		# check for existent data and update the ttl value
		if @data[ key ]? and @_check( key, @data[ key ] )
			# if ttl < 0 delete the key. otherwise reset the value
			if ttl >= 0
				@data[ key ] = @_wrap( @data[ key ].v, ttl, false )
			else
				@del( key )
			return true
		else
			# return false if key has not been found
			return false

		return

	# ## getTtl
	#
	# receive the ttl of a key.
	#
	# **Parameters:**
	#
	# * `key` ( String | Number ): cache key to check the ttl value of
	#
	# **Return**
	#
	# ( Number|undefined ): The timestamp in ms when the key will expire, 0 if it will never expire or undefined if it not exists
	#
	# **Example:**
	#
	#	myCache.getTtl( "myKey" )
	#
	getTtl: ( key )=>
		if not key
			return undefined

		# handle invalid key types
		if (err = @_isInvalidKey( key ))?
			throw err

		# check for existant data and update the ttl value
		if @data[ key ]? and @_check( key, @data[ key ] )
			_ttl = @data[ key ].t
			return _ttl
		else
			# return undefined if key has not been found
			return undefined

		return

	# ## keys
	#
	# list all keys within this cache
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
	keys: ( )=>
		_keys = Object.keys( @data )
		return _keys

	# ## has
	#
	# Check if a key is cached
	#
	# **Parameters:**
	#
	# * `key` ( String | Number ): cache key to check the ttl value
	#
	# **Return**
	#
	# ( Boolean ): A boolean that indicates if the key is cached
	#
	# **Example:**
	#
	#     _exists = myCache.has('myKey')
	#
	#     # true
	#
	has: ( key )=>
		_exists = @data[ key ]? and @_check( key, @data[ key ] )
		return _exists

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
	# flush the whole data and reset the stats
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
	
	
		# ## flushStats
	#
	# flush the stats and reset all counters to 0
	#
	# **Example:**
	#
	#     myCache.flushStats()
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
	flushStats: ()=>

		# reset stats
		@stats =
			hits: 0
			misses: 0
			keys: 0
			ksize: 0
			vsize: 0

		@emit( "flush_stats" )

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
	# internal housekeeping method.
	# Check all the cached data and delete the invalid values
	_checkData: ( startPeriod = true )=>
		# run the housekeeping method
		for key, value of @data
			@_check( key, value )

		if startPeriod and @options.checkperiod > 0
			@checkTimeout = setTimeout( @_checkData, ( @options.checkperiod * 1000 ), startPeriod )
			@checkTimeout.unref() if @checkTimeout? && @checkTimeout.unref?
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
		# data is invalid if the ttl is too old and is not 0
		# console.log data.t < Date.now(), data.t, Date.now()
		if data.t isnt 0 and data.t < Date.now()
			if @options.deleteOnExpire
				_retval = false
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
		key.toString().length

	# ## _getValLength
	#
	# internal method to calculate the value length
	_getValLength: ( value )=>
		if typeof value is "string"
			# if the value is a String get the real length
			value.length
		else if @options.forceString
			# force string if it's defined and not passed
			JSON.stringify( value ).length
		else if Array.isArray( value )
			# if the data is an Array multiply each element with a defined default length
			@options.arrayValueSize * value.length
		else if typeof value is "number"
			8
		else if typeof value?.then is "function"
			# if the data is a Promise, use defined default
			# (can't calculate actual/resolved value size synchronously)
			@options.promiseValueSize
		else if Buffer?.isBuffer(value)
			value.length
		else if value? and typeof value is "object"
			# if the data is an Object multiply each element with a defined default length
			@options.objectValueSize * Object.keys( value ).length
		else if typeof value is "boolean"
			8
		else
			# default fallback
			0

	# ## _error
	#
	# internal method to handle an error message
	_error: ( type, data = {} )=>
		# generate the error object
		error = new Error()
		error.name = type
		error.errorcode = type
		error.message = if @ERRORS[ type ]? then @ERRORS[ type ]( data ) else "-"
		error.data = data

		# return the error object
		return error

	# ## _initErrors
	#
	# internal method to generate error message templates
	_initErrors: =>
		@ERRORS = {}
		for _errT, _errMsg of @_ERRORS
			@ERRORS[ _errT ] = @createErrorMessage( _errMsg )

		return

	createErrorMessage: (errMsg) -> (args) -> errMsg.replace("__key", args.type)

	_ERRORS:
		"ENOTFOUND": "Key `__key` not found"
		"ECACHEFULL": "Cache max keys amount exceeded"
		"EKEYTYPE": "The key argument has to be of type `string` or `number`. Found: `__key`"
		"EKEYSTYPE": "The keys argument has to be an array."
		"ETTLTYPE": "The ttl argument has to be a number."
