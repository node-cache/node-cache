should = require( "should" )

_clone = require( "lodash/clone" )
VCache = require( "../" )

localCache = new VCache({
	stdTTL: 0
	useClone: false
	checkperiod: 0
})

localCacheTTL = new VCache({
	stdTTL: 0.3
	checkperiod: 0
})


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
	return randomstring
