should = require "should"
clone = require "lodash/clone"
{ stringify } = JSON

pkg = require "../package.json"
VCache = require "../"
{ randomString } = require "./helpers"

localCache = new VCache({
	stdTTL: 0
})

localCacheNoClone = new VCache({
	stdTTL: 0,
	useClones: false,
	checkperiod: 0
})


localCacheTTL = new VCache({
	stdTTL: 0.3,
	checkperiod: 0
})

# just for testing disable the check period
localCache._killCheckPeriod()

# store test state
state = {}

describe "`#{pkg.name}@#{pkg.version}` on `node@#{process.version}`", () ->

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
				should(err).be.null()
				# check stats (number of keys should be one more than before)
				1.should.equal localCache.getStats().keys - state.start.keys
				done()
				return
			return

		it "get a key", (done) ->
			localCache.get state.key, (err, res) ->
				state.n++
				should(err).be.null()
				state.value.should.eql res
				done()
			return

		it "get key names", (done) ->
			localCache.keys (err, res) ->
				state.n++
				should(err).be.null()
				[state.key].should.eql res
				done()
				return
			return

		it "try to get an undefined key", (done) ->
			localCache.get "yxz", (err, res) ->
				state.n++
				should(err).be.null()
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
			localCache.del "xxx", (err, res) ->
				state.n++
				should(err).be.null()
				0.should.eql res
				done()
				return
			return

		it "update key (and get it to check if the update worked)", (done) ->
			localCache.set state.key, state.value2, 0, (err, res) ->
				state.n++
				should(err).be.null()
				should(res).be.ok()

				# check if update worked
				localCache.get state.key, (err, res) ->
					state.n++
					should(err).be.null()
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
			localCache.del state.key, (err, res) ->
				state.n++
				should(err).be.null()
				1.should.eql res

				# check key numbers
				0.should.eql localCache.getStats().keys - state.start.keys

				# check if key was deleted
				localCache.get state.key, (err, res) ->
					state.n++
					should(err).be.null()
					should(res).be.undefined()
					done()
				return
			return

		it "set a key to 0", (done) ->
			localCache.set "zero", 0, 0, (err, res) ->
				state.n++
				should(err).be.null()
				should(res).be.ok()
				done()
				return
			return

		it "get previously set key", (done) ->
			localCache.get "zero", (err, res) ->
				state.n++
				should(err).be.null()
				0.should.eql res
				done()
				return
			return

		it "test promise storage", (done) ->
			deferred_value = "Some deferred value"
			if Promise?
				p = new Promise (fulfill, reject) ->
					fulfill deferred_value
					return
				p.then (value) ->
					deferred_value.should.eql value
					return
				localCacheNoClone.set "promise", p
				q = localCacheNoClone.get "promise"
				q.then (value) ->
					state.n++
					done()
					return
			else
				console.log "No Promises available in this node version (#{process.version})"
				this.skip()
			return

		after () ->
			count = 14
			count++ if Promise?
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
			should(res).be.ok()
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
			res = localCache.del "xxx"
			0.should.eql res
			return

		it "update key (and get it to check if the update worked)", () ->
			res = localCache.set state.key, state.value2, 0
			should(res).be.ok()

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
			res = localCache.del state.key
			1.should.eql res

			# check stats
			0.should.eql localCache.getStats().keys - state.start.keys
			return

		it "delete multiple keys (after setting them)", () ->
			keys = ["multiA", "multiB", "multiC"]
			# set the keys
			keys.forEach (key) ->
				res = localCache.set key, state.value3
				should(res).be.ok()
				return
			# check the keys
			keys.forEach (key) ->
				res = localCache.get key
				state.value3.should.eql res
				return
			# delete 2 of those keys
			res = localCache.del keys[0...2]
			2.should.eql res
			# try to get the deleted keys
			keys[0...2].forEach (key) ->
				res = localCache.get key
				should(res).be.undefined()
				return
			# get the not deleted key
			res = localCache.get keys[2]
			state.value3.should.eql res
			# delete this key, too
			res = localCache.del keys[2]
			1.should.eql res
			# try get the deleted key
			res = localCache.get keys[2]
			should(res).be.undefined()
			# re-deleting the keys should not have to delete an actual key
			res = localCache.del keys
			0.should.eql res
			return

		it "set a key to 0", () ->
			res = localCache.set "zero", 0
			should(res).be.ok()
			return

		it "get previously set key", () ->
			res = localCache.get "zero"
			0.should.eql res
			return

		it "set a key to an object clone", () ->
			res = localCache.set "clone", state.obj
			should(res).be.ok()
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
					should(err).be.null()
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
				console.log "\tSET: #{state.count} keys to: `#{state.val}` #{duration}ms (#{duration/state.count}ms per item)"
				return

			it "GET", () ->
				# this benchmark is a bit useless because the equality check eats up
				# around 3/4 of benchmark time
				start = Date.now()
				for key in state.keys
					state.n++
					state.val.should.eql localCache.get(key)
				duration = Date.now() - start
				console.log "\tGET: #{state.count} keys #{duration}ms (#{duration/state.count}ms per item)"
				return

			it "check stats", () ->
				stats = localCache.getStats()
				keys = localCache.keys()

				stats.keys.should.eql keys.length
				state.count.should.eql keys.length
				state.n.should.eql keys.length
				return

			after () ->
				console.log "\tBenchmark stats:"
				console.log stringify(localCache.getStats(), null, "\t")
				return
			return
		return


	describe "delete", () ->
		this.timeout(0)

		before () ->
			# don't override state because we still need `state.keys`
			Object.assign state,
				n: 0
				startKeys: localCache.getStats().keys
			return

		it "delete all previously set keys", () ->
			for i in [0...state.count]
				localCache.del state.keys[i], (err, count) ->
					state.n++
					should(err).be.null()
					1.should.eql count
					return

			state.n.should.eql state.count
			return

		it "delete keys again; should not delete anything", () ->
			for i in [0...state.count]
				localCache.del state.keys[i], (err, count) ->
					state.n++
					should(err).be.null()
					0.should.eql count
					return

			state.n.should.eql state.count*2
			localCache.getStats().keys.should.eql 0
			return
		return

	return
