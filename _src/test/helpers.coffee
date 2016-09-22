###
Generates a random string of given length

@param {Number} length - length of the returned string
@param {Boolean} withnumbers [true]

@return {String} generated random string
###
exports.randomString = (length, withnumbers = true) ->
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


###
Generates a random number between 0 and `max`

@param {Number} max

@return {Number} generated random number
###
exports.randomNumber = (max) -> Math.floor Math.random() * (max + 1)


###
Subtracts all objB keys from objA keys and returns the result.
Both objects should have identical keys with numeric values

@param {Object} objA
@param {Object} objB

@return {Object} Object with the diffed values
###
exports.diffKeys = (objA, objB) ->
	diff = {}

	for key of objA
		if objB.hasOwnProperty key
			diff[key] = objA[key] - objB[key]

	return diff
