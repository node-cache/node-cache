fs = require "fs"

should = require "should"
clone = require "lodash/clone"
{ stringify } = JSON

pkg = JSON.parse fs.readFileSync("package.json")

nodeCache = require "../"
{ randomNumber, randomString, diffKeys } = require "./helpers"

localCache = new nodeCache({
	stdTTL: 0
})

localCacheNoClone = new nodeCache({
	stdTTL: 0,
	useClones: false,
	checkperiod: 0
})


localCacheTTL = new nodeCache({
	stdTTL: 0.3,
	checkperiod: 0
})

localCacheNoDelete = new nodeCache({
	stdTTL: 0.3,
	checkperiod: 0
	deleteOnExpire: false
})

BENCH = {}

# just for testing disable the check period
localCache._killCheckPeriod()

# store test state
state = {}

describe "`#{pkg.name}@#{pkg.version}` on `node@#{process.version}`", () ->

	after ->
		txt = "Benchmark node@#{process.version}:"
		for type, ops of BENCH
			txt += "\n   - #{type}: #{ops.toFixed(1)} ops/s"
		console.log txt
		return

	describe "general callback-style", () ->
		before () ->
			state =
				n: 0
				start: clone localCache.getStats()
				key: randomString 10
				value: randomString 100
				value2: randomString 100
			return

		it "set a key", (done) ->
			localCache.set state.key, state.value, 0, (err, res) ->
				state.n++
				should.not.exist err
				# check stats (number of keys should be one more than before)
				1.should.equal localCache.getStats().keys - state.start.keys
				done()
				return
			return

		it "get a key", (done) ->
			localCache.get state.key, (err, res) ->
				state.n++
				should.not.exist err
				state.value.should.eql res
				done()
			return

		it "get key names", (done) ->
			localCache.keys (err, res) ->
				state.n++
				should.not.exist err
				[state.key].should.eql res
				done()
				return
			return

		it "try to get an undefined key", (done) ->
			localCache.get "yxz", (err, res) ->
				state.n++
				should.not.exist err
				should(res).be.undefined()
				done()
				return
			return

		it "catch an undefined key with callback", (done) ->
			key = "xxx"

			errorHandlerCallback = (err, res) ->
				state.n++
				"ENOTFOUND".should.eql err.name
				"Key `#{key}` not found".should.eql err.message
				# should(res).be.undefined()
				# AssertionError: expected null to be undefined
				# should be undefined by definition?
				return

			localCache.get key, errorHandlerCallback, true
			done()
			return

		it "catch an undefined key without callback", (done) ->
			key = "xxy"
			try
				localCache.get key, true
			catch err
				state.n++
				"ENOTFOUND".should.eql err.name
				"Key `#{key}` not found".should.eql err.message
				done()
			return

		it "catch undefined key without callback (errorOnMissing = true)", (done) ->
			key = "xxz"
			# the errorOnMissing option throws errors automatically
			# save old setting value
			originalThrowOnMissingValue = localCache.options.errorOnMissing
			localCache.options.errorOnMissing = true
			catched = false
			try
				localCache.get key
			catch err
				state.n++
				catched = true
				"ENOTFOUND".should.eql err.name
				"Key `#{key}` not found".should.eql err.message
			# the error should have been catched
			catched.should.be.true()
			# reset old setting value
			localCache.options.errorOnMissing = originalThrowOnMissingValue
			done()
			return

		it "try to delete an undefined key", (done) ->
			localCache.del "xxx", (err, count) ->
				state.n++
				should.not.exist err
				0.should.eql count
				done()
				return
			return

		it "update key (and get it to check if the update worked)", (done) ->
			localCache.set state.key, state.value2, 0, (err, res) ->
				state.n++
				should.not.exist err
				true.should.eql res

				# check if update worked
				localCache.get state.key, (err, res) ->
					state.n++
					should.not.exist err
					state.value2.should.eql res

					# check if stats didn't change
					1.should.eql localCache.getStats().keys - state.start.keys
					done()
					return
				return
			return

		it "delete the defined key", (done) ->
			# register event handler for first cache deletion
			localCache.once "del", (key, val) ->
				state.key.should.equal key
				state.value2.should.equal val
				return

			# delete the key
			localCache.del state.key, (err, count) ->
				state.n++
				should.not.exist err
				1.should.eql count

				# check key numbers
				0.should.eql localCache.getStats().keys - state.start.keys

				# check if key was deleted
				localCache.get state.key, (err, res) ->
					state.n++
					should.not.exist err
					should(res).be.undefined()
					done()
				return
			return

		it "set a key to 0", (done) ->
			localCache.set "zero", 0, 0, (err, res) ->
				state.n++
				should.not.exist err
				true.should.eql res
				done()
				return
			return

		it "get previously set key", (done) ->
			localCache.get "zero", (err, res) ->
				state.n++
				should.not.exist err
				0.should.eql res
				done()
				return
			return

		after () ->
			count = 14
			count.should.eql state.n
			return
		return


	describe "general sync-style", () ->
		before () ->
			localCache.flushAll()

			state =
				start: clone localCache.getStats()
				value: randomString 100
				value2: randomString 100
				value3: randomString 100
				key: randomString 10
				obj:
					a: 1
					b:
						x: 2
						y: 3
			return

		it "set key", () ->
			res = localCache.set state.key, state.value, 0
			true.should.eql res
			1.should.eql localCache.getStats().keys - state.start.keys
			return

		it "get key", () ->
			res = localCache.get state.key
			state.value.should.eql res
			return

		it "get key names", () ->
			res = localCache.keys()
			[state.key].should.eql res
			return

		it "delete an undefined key", () ->
			count = localCache.del "xxx"
			0.should.eql count
			return

		it "update key (and get it to check if the update worked)", () ->
			res = localCache.set state.key, state.value2, 0
			true.should.eql res

			# check if the update worked
			res = localCache.get state.key
			state.value2.should.eql res

			# stats should not have changed
			1.should.eql localCache.getStats().keys - state.start.keys
			return

		it "delete the defined key", () ->
			localCache.once "del", (key, val) ->
				state.key.should.eql key
				state.value2.should.eql val
				return
			count = localCache.del state.key
			1.should.eql count

			# check stats
			0.should.eql localCache.getStats().keys - state.start.keys
			return

		it "delete multiple keys (after setting them)", () ->
			keys = ["multiA", "multiB", "multiC"]
			# set the keys
			keys.forEach (key) ->
				res = localCache.set key, state.value3
				true.should.eql res
				return
			# check the keys
			keys.forEach (key) ->
				res = localCache.get key
				state.value3.should.eql res
				return
			# delete 2 of those keys
			count = localCache.del keys[0...2]
			2.should.eql count
			# try to get the deleted keys
			keys[0...2].forEach (key) ->
				res = localCache.get key
				should(res).be.undefined()
				return
			# get the not deleted key
			res = localCache.get keys[2]
			state.value3.should.eql res
			# delete this key, too
			count = localCache.del keys[2]
			1.should.eql count
			# try get the deleted key
			res = localCache.get keys[2]
			should(res).be.undefined()
			# re-deleting the keys should not have to delete an actual key
			count = localCache.del keys
			0.should.eql count
			return

		it "set a key to 0", () ->
			res = localCache.set "zero", 0
			true.should.eql res
			return

		it "get previously set key", () ->
			res = localCache.get "zero"
			0.should.eql res
			return

		it "set a key to an object clone", () ->
			res = localCache.set "clone", state.obj
			true.should.eql res
			return

		it "get cloned object", () ->
			res = localCache.get "clone"
			# should not be === equal
			state.obj.should.not.equal res
			# but should deep equal
			state.obj.should.eql res

			res.b.y = 42
			res2 = localCache.get "clone"
			state.obj.should.eql res2
			return

		it "test promise storage (fulfill before adding to cache)", (done) ->
			deferred_value = "Some deferred value"
			if Promise?
				p = new Promise (fulfill, reject) ->
					fulfill deferred_value
					return
				p.then (value) ->
					deferred_value.should.eql value
					return
				localCache.set "promise", p
				q = localCache.get "promise"
				q.then (value) ->
					done()
					return
			else
				if not process.env.SILENT_MODE?
					console.log "No Promises available in this node version (#{process.version})"
				this.skip()
			return

		it "test promise storage (fulfill after adding to cache)", (done) ->
			deferred_value = "Some deferred value"
			if Promise?
				called  = 0
				callStub = () ->
					called++
					if called is 2
						done()
					return

				p = new Promise (fulfill, reject) ->
					fulfiller = () ->
						fulfill deferred_value
						return
					setTimeout fulfiller, 250
					return
				p.then (value) ->
					deferred_value.should.eql value
					callStub()
					return
				localCache.set "promise", p
				q = localCache.get "promise"
				q.then (value) ->
					deferred_value.should.eql value
					callStub()
					return
			else
				if not process.env.SILENT_MODE?
					console.log "No Promises available in this node version (#{process.version})"
				this.skip()
			return

		it "test es6 map", () ->
			unless Map?
				if not process.env.SILENT_MODE?
					console.log "No Maps available in this node version (#{process.version})"
				this.skip()
				return

			key = randomString 10
			map = new Map([ ["firstkey", "firstvalue"], ["2ndkey", "2ndvalue"], ["thirdkey", "thirdvalue"] ])

			localCache.set key, map

			map.set "fourthkey", "fourthvalue"

			cached_map = localCache.get key
			should( cached_map.get("2ndkey") ).eql "2ndvalue"
			should( cached_map.get "fourthkey" ).be.undefined()
			return

		it "test `useClones = true` with an Object", () ->
			key = randomString 10
			value =
				a: 123
				b: 456
			c = 789

			localCache.set key, value
			value.a = c

			value.should.not.be.eql localCache.get(key)
			return

		it "test `useClones = false` with an Object", () ->
			key = randomString 10
			value =
				a: 123
				b: 456
			c = 789

			localCacheNoClone.set key, value
			value.a = c

			should( value is localCacheNoClone.get(key) ).be.true()
			return

		return

	describe "correct and incorrect key types", () ->
		describe "number", () ->
			before () ->
				state =
					keys: []
					val: randomString 20

				for [1..10]
					state.keys.push randomNumber 100000
				return

			it "set", () ->
				for key in state.keys
					localCache.set key, state.val, (err, res) ->
						should.not.exist err
						true.should.eql res
						return
				return

			it "get", () ->
				localCache.get state.keys[0], (err, res) ->
					should.not.exist err
					state.val.should.eql res
					return
				return

			it "mget", () ->
				localCache.mget state.keys[0..1], (err, res) ->
					should.not.exist err
					# generate prediction
					prediction = {}
					prediction[state.keys[0]] = state.val
					prediction[state.keys[1]] = state.val
					prediction.should.eql res
					return
				return

			it "del single", () ->
				localCache.del state.keys[0], (err, count) ->
					should.not.exist err
					1.should.eql count
					return
				return

			it "del multi", () ->
				localCache.del state.keys[1..2], (err, count) ->
					should.not.exist err
					2.should.eql count
					return
				return

			it "ttl", (done) ->
				success = localCache.ttl state.keys[3], 0.3
				true.should.eql success

				res = localCache.get state.keys[3]
				state.val.should.eql res

				setTimeout(() ->
					res = localCache.get state.keys[3]
					should.not.exist res
					done()
					return
				, 400)
				return

			it "getTtl", () ->
				now = Date.now()
				success = localCache.ttl state.keys[4], 0.5
				true.should.eql success

				ttl = localCache.getTtl state.keys[4]
				(485 < (ttl - now) < 510).should.eql true
				return

			after () ->
				localCache.flushAll false
				return
			return

		describe "string", () ->
			before () ->
				state =
					keys: []
					val: randomString 20

				for [1..10]
					state.keys.push randomString 10
				return

			it "set", () ->
				for key in state.keys
					localCache.set key, state.val, (err, res) ->
						should.not.exist err
						true.should.eql res
						return
				return

			it "get", () ->
				localCache.get state.keys[0], (err, res) ->
					should.not.exist err
					state.val.should.eql res
					return
				return

			it "mget", () ->
				localCache.mget state.keys[0..1], (err, res) ->
					should.not.exist err
					# generate prediction
					prediction = {}
					prediction[state.keys[0]] = state.val
					prediction[state.keys[1]] = state.val
					prediction.should.eql res
					return
				return

			it "del single", () ->
				localCache.del state.keys[0], (err, count) ->
					should.not.exist err
					1.should.eql count
					return
				return

			it "del multi", () ->
				localCache.del state.keys[1..2], (err, count) ->
					should.not.exist err
					2.should.eql count
					return
				return

			it "ttl", (done) ->
				success = localCache.ttl state.keys[3], 0.3
				true.should.eql success

				res = localCache.get state.keys[3]
				state.val.should.eql res

				setTimeout(() ->
					res = localCache.get state.keys[3]
					should.not.exist res
					done()
					return
				, 400)
				return

			it "getTtl", () ->
				now = Date.now()
				success = localCache.ttl state.keys[4], 0.5
				true.should.eql success

				ttl = localCache.getTtl state.keys[4]
				(485 < (ttl - now) < 510).should.eql true
				return
			return

		describe "boolean - invalid type", () ->
			before () ->
				state =
					keys: [true, false]
					val: randomString 20
				return

			it "set sync-style", () ->
				(() -> localCache.set(state.keys[0], state.val)).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
				})
				return

			it "set cb-style", () ->
				localCache.set state.keys[0], state.val, (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
					})
					return
				return

			it "get sync-style", () ->
				(() -> localCache.get(state.keys[0])).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
				})
				return

			it "get cb-style", () ->
				localCache.get state.keys[0], (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
					})
					return
				return

			it "mget sync-style", () ->
				(() -> localCache.mget(state.keys)).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
				})
				return

			it "mget cb-style", () ->
				localCache.mget state.keys, (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
					})
					return
				return

			it "del single sync-style", () ->
				(() -> localCache.del(state.keys[0])).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
				})
				return

			it "del single cb-style", () ->
				localCache.del state.keys[0], (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
					})
					return
				return

			it "del multi sync-style", () ->
				(() -> localCache.del(state.keys)).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
				})
				return

			it "del multi cb-style", () ->
				localCache.del state.keys, (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
					})
					return
				return

			it "ttl sync-style", () ->
				(() -> localCache.ttl(state.keys[0], 10)).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
				})
				return

			it "ttl cb-style", () ->
				localCache.ttl state.keys[0], 10, (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
					})
					return
				return

			it "getTtl sync-style", () ->
				(() -> localCache.getTtl(state.keys[0])).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
				})
				return

			it "getTtl cb-style", () ->
				localCache.getTtl state.keys[0], (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `boolean`"
					})
					return
				return
			return

		describe "object - invalid type", () ->
			before () ->
				state =
					keys: [{ a: 1 }, { b: 2 }]
					val: randomString 20
				return

			it "set sync-style", () ->
				(() -> localCache.set(state.keys[0], state.val)).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `object`"
				})
				return

			it "set cb-style", () ->
				localCache.set state.keys[0], state.val, (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `object`"
					})
					return
				return

			it "get sync-style", () ->
				(() -> localCache.get(state.keys[0])).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `object`"
				})
				return

			it "get cb-style", () ->
				localCache.get state.keys[0], (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `object`"
					})
					return
				return

			it "mget sync-style", () ->
				(() -> localCache.mget(state.keys)).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `object`"
				})
				return

			it "mget cb-style", () ->
				localCache.mget state.keys, (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `object`"
					})
					return
				return

			it "del single sync-style", () ->
				(() -> localCache.del(state.keys[0])).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `object`"
				})
				return

			it "del single cb-style", () ->
				localCache.del state.keys[0], (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `object`"
					})
					return
				return

			it "del multi sync-style", () ->
				(() -> localCache.del(state.keys)).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `object`"
				})
				return

			it "del multi cb-style", () ->
				localCache.del state.keys, (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `object`"
					})
					return
				return

			it "ttl sync-style", () ->
				(() -> localCache.ttl(state.keys[0], 10)).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `object`"
				})
				return

			it "ttl cb-style", () ->
				localCache.ttl state.keys[0], 10, (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `object`"
					})
					return
				return

			it "getTtl sync-style", () ->
				(() -> localCache.getTtl(state.keys[0])).should.throw({
					name: "EKEYTYPE"
					message: "The key argument has to be of type `string` or `number`. Found: `object`"
				})
				return

			it "getTtl cb-style", () ->
				localCache.getTtl state.keys[0], (err, res) ->
					should.not.exist res
					should(err).be.an.Error()
					should(err).match({
						name: "EKEYTYPE"
						message: "The key argument has to be of type `string` or `number`. Found: `object`"
					})
					return
				return
			return

		return

	describe "flush", () ->
		before () ->
			state =
				n: 0
				count: 100
				startKeys: localCache.getStats().keys
				keys: []
				val: randomString 20
			return

		it "set keys", () ->
			for [1..state.count]
				key = randomString 7
				state.keys.push key

			state.keys.forEach (key) ->
				localCache.set key, state.val, (err, res) ->
					state.n++
					should.not.exist err
					return
				return

			state.count.should.eql state.n
			(state.startKeys + state.count).should.eql localCache.getStats().keys
			return

		it "flush keys", () ->
			localCache.flushAll false

			0.should.eql localCache.getStats().keys
			{}.should.eql localCache.data
			return
		return


	describe "many", () ->
		before () ->
			state =
				n: 0
				count: 100000
				keys: []
				val: randomString 20

			for [1..state.count]
				key = randomString 7
				state.keys.push key
			return

		describe "BENCHMARK", () ->
			this.timeout(0)
			# hack so mocha always shows timing information
			this.slow(1)

			it "SET", () ->
				start = Date.now()
				# not using forEach because it's magnitude 10 times slower than for
				# and we are into a benchmark
				for key in state.keys
					should(localCache.set key, state.val, 0).be.ok()
				duration = Date.now() - start
				if not process.env.SILENT_MODE?
					console.log "\tSET: #{state.count} keys to: `#{state.val}` #{duration}ms (#{duration/state.count}ms per item)"
				else
					BENCH[ "SET" ] = 1/(( duration/1000 )/state.count)
				return

			it "GET", () ->
				# this benchmark is a bit useless because the equality check eats up
				# around 3/4 of benchmark time
				start = Date.now()
				for key in state.keys
					state.n++
					state.val.should.eql localCache.get(key)
				duration = Date.now() - start
				if not process.env.SILENT_MODE?
					console.log "\tGET: #{state.count} keys #{duration}ms (#{duration/state.count}ms per item)"
				else
					BENCH[ "GET" ] = 1/(( duration/1000 )/state.count)
				return

			it "check stats", () ->
				stats = localCache.getStats()
				keys = localCache.keys()

				stats.keys.should.eql keys.length
				state.count.should.eql keys.length
				state.n.should.eql keys.length
				return

			after () ->
				if not process.env.SILENT_MODE?
					console.log "\tBenchmark stats:"
					console.log stringify(localCache.getStats(), null, "\t")
				return
			return
		return


	describe "delete", () ->
		this.timeout(0)

		before () ->
			# don't override state because we still need `state.keys`
			state.n = 0
			state.startKeys = localCache.getStats().keys
			return

		it "delete all previously set keys", () ->
			for i in [0...state.count]
				localCache.del state.keys[i], (err, count) ->
					state.n++
					should.not.exist err
					1.should.eql count
					return

			state.n.should.eql state.count
			return

		it "delete keys again; should not delete anything", () ->
			for i in [0...state.count]
				localCache.del state.keys[i], (err, count) ->
					state.n++
					should.not.exist err
					0.should.eql count
					return

			state.n.should.eql state.count*2
			localCache.getStats().keys.should.eql 0
			return
		return


	describe "stats", () ->
		before () ->
			state =
				n: 0
				start: clone localCache.getStats()
				count: 5
				keylength: 7
				valuelength: 50
				keys: []
				values: []

			for [1..state.count*2]
				key = randomString state.keylength
				value = randomString state.valuelength
				state.keys.push key
				state.values.push value

				localCache.set key, value, 0, (err, success) ->
					state.n++
					should.not.exist err
					should(success).be.ok()
					return
			return

		it "get and remove `count` elements", () ->
			for i in [1..state.count]
				localCache.get state.keys[i], (err, res) ->
					state.n++
					should.not.exist err
					state.values[i].should.eql res
					return

			for i in [1..state.count]
				localCache.del state.keys[i], (err, count) ->
					state.n++
					should.not.exist err
					1.should.eql count
					return

			after = localCache.getStats()
			diff = diffKeys after, state.start

			diff.hits.should.eql 5
			diff.keys.should.eql 5
			diff.ksize.should.eql state.count * state.keylength
			diff.vsize.should.eql state.count * state.valuelength
			return

		it "generate `count` misses", () ->
			for i in [1..state.count]
				# 4 char key should not exist
				localCache.get "xxxx", (err, res) ->
					state.n++
					should.not.exist err
					should(res).be.undefined()
					return

			after = localCache.getStats()
			diff = diffKeys after, state.start

			diff.misses.should.eql 5
			return

		it "check successful runs", () ->
			state.n.should.eql 5 * state.count
			return
		return


	describe "multi", () ->
		before () ->
			state =
				n: 0
				count: 100
				startKeys: localCache.getStats().keys
				value: randomString 20
				keys: []

			for [1..state.count]
				key = randomString 7
				state.keys.push key

			for key in state.keys
				localCache.set key, state.value, 0, (err, res) ->
					state.n++
					should.not.exist err
					return
			return

		it "generate a sub-list of keys", () ->
			state.getKeys = state.keys.splice 50, 5
			return

		it "generate prediction", () ->
			state.prediction = {}
			for key in state.getKeys
				state.prediction[key] = state.value
			return

		it "try to mget with a single key", () ->
			localCache.mget state.getKeys[0], (err, res) ->
				state.n++
				should.exist err
				"Error".should.eql err.constructor.name
				"EKEYSTYPE".should.eql err.name
				should(res).be.undefined()
				return
			return

		it "mget the sub-list", () ->
			localCache.mget state.getKeys, (err, res) ->
				state.n++
				should.not.exist err
				state.prediction.should.eql res
				return
			return

		it "delete keys in the sub-list", () ->
			localCache.del state.getKeys, (err, count) ->
				state.n++
				should.not.exist err
				state.getKeys.length.should.eql count
				return
			return

		it "try to mget the sub-list again", () ->
			localCache.mget state.getKeys, (err, res) ->
				state.n++
				should.not.exist err
				{}.should.eql res
				return
			return

		it "check successful runs", () ->
			state.n.should.eql state.count + 4
			return
		return


	describe "ttl", () ->
		before () ->
			state =
				n: 0
				val: randomString 20
				key1: "k1_#{randomString 20}"
				key2: "k2_#{randomString 20}"
				key3: "k3_#{randomString 20}"
				key4: "k4_#{randomString 20}"
				key5: "k5_#{randomString 20}"
				now: Date.now()
			state.keys = [state.key1, state.key2, state.key3, state.key4, state.key5]
			return

		it "set a key with ttl", () ->
			localCache.set state.key1, state.val, 0.7, (err, res) ->
				should.not.exist err
				true.should.eql res
				ts = localCache.getTtl state.key1
				if state.now < ts < state.now + 300
					throw new Error "Invalid timestamp"
				return
			return

		it "check this key immediately", () ->
			localCache.get state.key1, (err, res) ->
				should.not.exist err
				state.val.should.eql res
				return
			return

		it "before it times out", (done) ->
			setTimeout(() ->
				state.n++
				localCache.get state.key1, (err, res) ->
					should.not.exist err
					state.val.should.eql res
					done()
					return
			, 20)
			return

		it "and after it timed out", (done) ->
			setTimeout(() ->
				ts = localCache.getTtl state.key1
				should.not.exist ts

				state.n++
				localCache.get state.key1, (err, res) ->
					should.not.exist err
					should(res).be.undefined()
					done()
					return
				return
			, 700)
			return

		it "set another key with ttl", () ->
			localCache.set state.key2, state.val, 0.5, (err, res) ->
				should.not.exist err
				true.should.eql res
				return
			return

		it "check this key immediately", () ->
			localCache.get state.key2, (err, res) ->
				should.not.exist err
				state.val.should.eql res
				return
			return

		it "before it times out", (done) ->
			setTimeout(() ->
				state.n++

				localCache.get state.key2, (err, ts) ->
					if state.now < ts < state.now + 300
						throw new Error "Invalid timestamp"
					return

				localCache.get state.key2, (err, res) ->
					should.not.exist err
					state.val.should.eql res
					done()
					return
				return
			, 20)
			return

		it "and after it timed out, too", (done) ->
			setTimeout(() ->
				ts = localCache.getTtl state.key2
				should.not.exist ts

				state.n++
				localCache.get state.key2, (err, res) ->
					should.not.exist err
					should(res).be.undefined()
					done()
					return
				return
			, 500)
			return

		describe "test the automatic check", (done) ->
			innerState = null

			before (done) ->
				setTimeout(() ->
					innerState =
						startKeys: localCache.getStats().keys
						key: "autotest"
						val: randomString 20

					done()
					return
				, 1000)
				return

			it "set a key with ttl", (done) ->
				localCache.once "set", (key) ->
					innerState.key.should.eql key
					return

				localCache.set innerState.key, innerState.val, 0.5, (err, res) ->
					should.not.exist err
					true.should.eql res
					(innerState.startKeys + 1).should.eql localCache.getStats().keys
					# event handler should have been fired
					0.should.eql localCache.listeners("set").length
					done()
					return
				return

			it "and check it's existence", () ->
				localCache.get innerState.key, (err, res) ->
					should.not.exist err
					innerState.val.should.eql res
					return
				return

			it "wait for 'expired' event", (done) ->
				localCache.once "expired", (key, val) ->
					innerState.key.should.eql key
					(key not in state.keys).should.eql true
					should(localCache.data[key]).be.undefined()
					done()
					return

				setTimeout(() ->
					# trigger ttl check, which will trigger the `expired` event
					localCache._checkData false
					return
				, 550)
				return
			return

		describe "more ttl tests", () ->

			it "set a third key with ttl", () ->
				localCache.set state.key3, state.val, 100, (err, res) ->
					should.not.exist null
					true.should.eql res
					return
				return

			it "check it immediately", () ->
				localCache.get state.key3, (err, res) ->
					should.not.exist err
					state.val.should.eql res
					return
				return

			it "set ttl to the invalid key", () ->
				localCache.ttl "#{state.key3}false", 0.3, (err, wasSet) ->
					should.not.exist err
					false.should.eql wasSet
					return
				return

			it "set ttl to the correct key", () ->
				localCache.ttl state.key3, 0.3, (err, wasSet) ->
					should.not.exist err
					true.should.eql wasSet
					return
				return

			it "check if the key still exists", () ->
				localCache.get state.key3, (err, res) ->
					should.not.exist err
					state.val.should.eql res
					return
				return

			it "wait until ttl has ended and check if the key was deleted", (done) ->
				setTimeout(() ->
					res = localCache.get state.key3
					should(res).be.undefined()
					should(localCache.data[state.key3]).be.undefined()
					done()
					return
				, 500)
				return

			it "set a key with ttl = 100s (default: infinite), reset it's ttl to default and check if it still exists", () ->
				localCache.set state.key4, state.val, 100, (err, res) ->
					should.not.exist err
					true.should.eql res

					# check immediately
					localCache.get state.key4, (err, res) ->
						should.not.exist err
						state.val.should.eql res

						# set ttl to false key
						localCache.ttl "#{state.key4}false", (err, wasSet) ->
							should.not.exist err
							false.should.eql wasSet
							return

						# set default ttl (0) to the right key
						localCache.ttl state.key4, (err, wasSet) ->
							should.not.exist err
							true.should.eql wasSet

							# and check if it still exists
							res = localCache.get state.key4
							state.val.should.eql res
							return
						return
					return
				return

			it "set a key with ttl = 100s (default: 0.3s), reset it's ttl to default, check if it still exists, and wait for its timeout", (done) ->
				localCacheTTL.set state.key5, state.val, 100, (err, res) ->
					should.not.exist err
					true.should.eql res

					# check immediately
					localCacheTTL.get state.key5, (err, res) ->
						should.not.exist err
						state.val.should.eql res

						# set ttl to false key
						localCacheTTL.ttl "#{state.key5}false", (err, wasSet) ->
							should.not.exist err
							false.should.eql wasSet
							return

						# set default ttl (0.3) to right key
						localCacheTTL.ttl state.key5, (err, wasSet) ->
							should.not.exist err
							true.should.eql wasSet
							return

						# and check if it still exists
						localCacheTTL.get state.key5, (err, res) ->
							should.not.exist err
							state.val.should.eql res

							setTimeout(() ->
								res = localCacheTTL.get state.key5
								should.not.exist res

								localCacheTTL._checkData false

								# deep dirty check if key was deleted
								should(localCacheTTL.data[state.key5]).be.undefined()
								done()
								return
							, 350)
							return
						return
				return


			it "set a key key with a cache initialized with no automatic delete on expire should be undefined", (done) ->
				localCacheNoDelete.set state.key1, state.val, (err, res) ->
				setTimeout(() ->
					res = localCacheNoDelete.get state.key1
					should(res).eql(undefined)
					done()
					return
				, 500)
				return

			it "test issue #78 with expire event not fired", ( done )->
				@timeout( 6000 )
				localCacheTTL2 = new nodeCache({
					stdTTL: 1,
					checkperiod: 0.5
				})
				expCount = 0
				expkeys = [ "ext78_test:a", "ext78_test:b" ]

				localCacheTTL2.set( expkeys[ 0 ], expkeys[ 0 ], 2)
				localCacheTTL2.set( expkeys[ 1 ], expkeys[ 1 ], 3)

				localCacheTTL2.on "expired", ( key, value )->
					key.should.eql( expkeys[ expCount ] )
					value.should.eql( expkeys[ expCount ] )
					expCount++
					return

				setTimeout( ->
					expCount.should.eql( 2 )
					localCacheTTL2.close()
					done()
				, 5000 )
			return

		return

	describe "clone", () ->
		it "a function", (done) ->
			key = randomString 10

			value = () ->
				done()
				return

			localCache.set key, value

			fn = localCache.get key
			fn()
			return

		it "a regex", () ->
			key = randomString 10
			regex = new RegExp "\\b\\w{4}\\b", "g"
			match = "king"
			noMatch = "bla"

			true.should.eql regex.test(match)
			false.should.eql regex.test(noMatch)

			localCache.set key, regex
			cachedRegex = localCache.get key

			true.should.eql cachedRegex.test(match)
			false.should.eql cachedRegex.test(noMatch)
			return
		return

	return
