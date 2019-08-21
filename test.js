const test = require(".");

const cache = new test({
	enableLegacyCallbacks: true
});

cache.set("a", "A", 0, (err, res) => {
	console.log("nice:", err, res);

	console.log(cache.get("a"));
});
