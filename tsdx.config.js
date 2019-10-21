const { readFileSync } = require("fs");
const pkg = JSON.parse(readFileSync("./package.json").toString());

function toStr(num) {
	return (num < 10) ? `0${num}` : num;
}

function getDateString() {
	const date = new Date();
	return `${date.getFullYear()}-${toStr(date.getMonth())}-${toStr(date.getDay())}`;
}

function getMaintainers() {
	return pkg.maintainers.reduce((acc, maintainer, index) => {
		return acc + (() => {
			switch (index) {
				case 0: return "";
				case pkg.maintainers.length - 1: return " and ";
				default: return ", ";
			}
		})() + `${maintainer.name} (${maintainer.url})`
	}, "");
}

const banner = `
/*
 * ${pkg.name} ${pkg.version} (${getDateString()})
 * ${pkg.homepage}
 *
 * Released under the MIT license
 * ${pkg.homepage}/blob/master/LICENSE
 *
 * Maintained by ${getMaintainers()}
*/
`

module.exports = {
	rollup(config, _options) {
		config.output.banner = banner;
		return config;
	}
}
