module.exports = class VariableCache
	constructor: ( @options = {} )->

		# container for cached dtaa
		@data = {}

		# module options
		@options = _.extend(
			# convert all elements to string 
			forceString: true
			# used standard size for calculating value size
			objectValueSize: 80
			arrayValueSize: 40
			# standard time to live. 0 = infinity; 10 = 10ms; 1m = 1 Min. ...
			stdTTL: 0
		, @options )

		# statistics container
		@stats = 
			hits: 0
			misses: 0
			keys: 0
			ksize: 0 # cummulierte Länge aller Keynamen
			vsize: 0 # cummulierte Länge aller Values. Nur bei Strings relevant

	# ## get
	#
	# get a cached key and change the stats
	#
	# **Parameters:**
	#
	# * `key` ( String ): cache key
	# * `cb` ( Function ): Callback function
	# 
	# **Example:**
	#     
	#     myCache.key "myKey", ( err, val )->
	#       console.log( err, val )
	#
	get: ( key, cb )->

		# get data and incremet stats
		if @data[ key ]? and @_check( key, @data[ key ] )
			@stats.hits++
			cb( null, @_unwrap( @data[ key ] ) )
		else
			# if not found return a error
			@stats.misses++
			@_error( 'not-found', method: "get", cb )
		return
	
	# ## set
	#
	# set a cached key and change the stats
	#
	# **Parameters:**
	#
	# * `key` ( String ): cache key
	# * `value` ( Any ): A element to cache. If the option `option.forceString` is `true` the module trys to translate it to a serialized JSON
	# * `[ ttl ]` ( Number | String ): The time to live. Possible example Value are: `10` = 10 ms; `0` = infinity; `5m` = 5 Minutes; The following extensions are allowed: s, m, h, d
	# * `cb` ( Function ): Callback function
	# 
	# **Example:**
	#     
	#     myCache.set "myKey", "my_String Value", ( err, success )->
	#       console.log( err, success ) 
	#     
	#     myCache.set "myKey", "my_String Value", "10h", ( err, success )->
	#       console.log( err, success ) 
	#
	set: ( key, value, ttl, cb )=>
		# internal helper variables
		existend = false
		
		# force the data to string
		if @options.forceString and not _.isString( value )
			value = JSON.stringify( value ) 

		# remap the arguments if `ttl` is not passed
		if arguments.length is 3
			cb = ttl
			ttl = @options.stdTTL
		
		# remove existing data from stats
		if @data[ key ]
			existend = true
			@stats.vsize -= @_getValLength( @_unwrap( data[ key ] ) )
		
		# set the value
		@data[ key ] = @_wrap( value )
		@stats.vsize += @_getValLength( value )

		# only add the keys and key-size if the key is new
		if not existend
			@stats.ksize += @_getKeyLength( key ) 
			@stats.keys++
		
		# return true
		cb( cb, true )
		return
	
	# ## del
	#
	# remove a key from the cache
	#
	# **Parameters:**
	#
	# * `key` ( String ): cache key to delete
	# * `cb` ( Function ): Callback function
	# 
	# **Example:**
	#     
	#     myCache.del( "myKey" )
	#     
	#     myCache.del( "myKey", ( err, success )->
	#       console.log( err, success ) 
	#
	del: ( key, cb=-> )=>
		# only delete if existend
		if @data[ key ]?
			# calc the stats
			@stats.vsize -= @_getValLength( @_unwrap( @data[ key ] ) )
			@stats.ksize -= @_getKeyLength( key )
			@stats.keys--
			# delete the value
			delete @data[ key ]
			# return true
			cb( null, true )
		else
			# if the key has not been found return an error
			@stats.misses++
			@_error( 'not-found', method: "dl", cb )
		return
	
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
	
	# ## checkData
	# Housekeeping mehtod.
	# Check all the cached data and delete the invalid values
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
	# myCache.chackData()
	# 
	checkData: =>
		# run the housekeeping method
		for key, value of @data
			@_check( key, vData )
		return
	
	# internal method to wrap a value in an object with some metadata
	_wrap: ( value, ttl = @options.stdTTL )=>
		# define the time to live
		if ttl
			livetime = new Date().getTime() + utils.getMilliSeconds( ttl )
		
		# return teh wrapped value
		oReturn =
			t: livetime
			v: value

	# internal method to extract get the value out of the wrapped value
	_unwrap: ( value )=>
		value.v or null
	
	# internal method the calculate the key length
	_getKeyLength: ( key )=>
		key.length
	
	# internal method to calculate the value length
	_getValLength: ( value )=>
		if _.isString( value )
			# if the value is a String get the real length
			value.length
		else if @options.forceString
			# force string if it's defined and not passed
			JSON.stringify( value ).length
		else if _.isArray( value )
			# if the data is an Array multiply each element with a defined default length
			@options.arrayValueSize * value.length
		else
			# if the data is an Object multiply each element with a defined default length
			@options.objectValueSize * _.size( value )
		
	# internal method the check the value. If it's not valid any moe delete it
	_check: ( key, data )=>
		now = new Date().getTime()

		# data is invalid if the ttl is to old and is not 0
		if data.t < now and date.t isnt 0
			@del( key )
			false
		else
			true
	
	# internal method to handle an error message
	_error: ( type, data = {}, cb )=>
		# generate the error object
		error = 
			errorcode: type
			msg: "-"
			data: data
		if cb and _.isFunction( cb )
			# return the error
			cb( error, null )
			return
		else
			# if no callbach is defined return the error object
			error