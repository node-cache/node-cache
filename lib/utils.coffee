# configure the time method
# define options and the sequential multiplicators
_timeConfig = 
	types: [ "ms", "s", "m", "h", "d" ]
	multiConfig: [ 1, 1000, 60, 60, 24 ]
# calculate the final multiplacatos
_timeConfig.multi = _.reduce( _timeConfig.multiConfig, ( v1, v2, idx, ar )->
	v1.push ( v1[ idx-1 ] or 1 ) * v2
	v1
, [] )

module.exports = 
	# ## getMilliSeconds
	#
	# get the milliseconds form a String like "5s" or "3h". Format is "[ time ][ type ]"  
	# Possible types are [ "ms", "s", "m", "h", "d" ]
	#
	# **Parameters:**
	#
	# * `time` ( String|Number ): the time to convert
	# 
	# **Returns:**
	#
	# ( Number ): timespan in miliseconds
	# 
	# **Example:**
	#
	#     utils.getMilliSeconds( 100 )   # 100
	#     utils.getMilliSeconds( "100" ) # 100
	#     utils.getMilliSeconds( "5s" )  # 5000
	#     utils.getMilliSeconds( "3m" )  # 180000
	#     utils.getMilliSeconds( "3d" )  # 259200000
	#     utils.getMilliSeconds( "aaa" ) # null
	#
	getMilliSeconds: ( time )=>
		# slice the input to time and type
		type = time.replace( /\d+/gi, '' )
		time = parseInt( time.replace( /\D+/gi, '' ), 10 )

		# find the type
		iType = _timeConfig.types.indexOf( type )
		
		# multiplicate the time
		if iType >= 0
			time * _timeConfig.multi[ iType ]	
		else if isNaN( time )
			null
		else
			time
