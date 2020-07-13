/*
Generates a random string of given length

@param {Number} length - length of the returned string
@param {Boolean} withnumbers [true]

@return {String} generated random string
*/
exports.randomString = function(length?: number, withnumbers?: boolean) {
	if (withnumbers == null) {
		withnumbers = true;
	}
	let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	if (withnumbers) {
		chars += "0123456789";
	}

	const string_length = length || 5;
	let randomstring = "";
	let i = 0;

	while (i < string_length) {
		const rnum = Math.floor(Math.random() * chars.length);
		randomstring += chars.substring(rnum, rnum + 1);
		i++;
	}

	return randomstring;
};

/*
Generates a random number between 0 and `max`

@param {Number} max

@return {Number} generated random number
*/
exports.randomNumber = (max: number) => Math.floor(Math.random() * (max + 1));

/*
Subtracts all objB keys from objA keys and returns the result.
Both objects should have identical keys with numeric values

@param {Object} objA
@param {Object} objB

@return {Object} Object with the diffed values
*/
exports.diffKeys = function(objA: any, objB: any) {
	const diff: any = {};

	for (let key in objA) {
		if (objB.hasOwnProperty(key)) {
			diff[key] = objA[key] - objB[key];
		}
	}

	return diff;
};
