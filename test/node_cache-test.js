(function() {
  var VCache, ks, localCache, randomString, vs, _;
  _ = require("underscore");
  VCache = require("../lib/node_cache");
  localCache = new VCache({
    stdTTL: '15m'
  });
  randomString = function(length, withnumbers) {
    var chars, i, randomstring, rnum, string_length;
    if (withnumbers == null) {
      withnumbers = true;
    }
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    if (withnumbers) {
      chars += "0123456789";
    }
    string_length = length || 5;
    randomstring = "";
    i = 0;
    while (i < string_length) {
      rnum = Math.floor(Math.random() * chars.length);
      randomstring += chars.substring(rnum, rnum + 1);
      i++;
    }
    return randomstring;
  };
  vs = [];
  ks = [];
  module.exports = {
    "general": function(beforeExit, assert) {
      var key, n, start, value, value2;
      n = 0;
      start = _.clone(localCache.getStats());
      value = randomString(100);
      value2 = randomString(100);
      key = randomString(10);
      localCache.set(key, value, 0, function(err, res) {
        assert.isNull(err, err);
        n++;
        assert.equal(1, localCache.getStats().keys - start.keys);
        localCache.get(key, function(err, res) {
          var pred;
          n++;
          pred = {};
          pred[key] = value;
          return assert.eql(pred, res);
        });
        localCache.get("xxx", function(err, res) {
          n++;
          assert.isNull(err, err);
          return assert.eql({}, res);
        });
        localCache.del("xxx", function(err, res) {
          n++;
          assert.isNull(err, err);
          return assert.ok(res);
        });
        localCache.set(key, value2, 0, function(err, res) {
          n++;
          assert.isNull(err, err);
          assert.ok(res, err);
          return localCache.get(key, function(err, res) {
            var pred;
            n++;
            pred = {};
            pred[key] = value2;
            assert.eql(pred, res);
            return assert.equal(1, localCache.getStats().keys - start.keys);
          });
        });
        return localCache.del(key, function(err, res) {
          n++;
          assert.isNull(err, err);
          assert.ok(res);
          assert.equal(0, localCache.getStats().keys - start.keys);
          return localCache.get(key, function(err, res) {
            n++;
            assert.isNull(err, err);
            return assert.eql({}, res);
          });
        });
      });
      return beforeExit(function() {
        return assert.equal(8, n, "not exited");
      });
    },
    "many": function(beforeExit, assert) {
      var count, i, key, n, time, val, _i, _j, _len, _len2;
      n = 0;
      count = 100000;
      console.log("START MANY TEST/BENCHMARK.\nSet, Get and check " + count + " elements");
      val = randomString(20);
      for (i = 1; 1 <= count ? i <= count : i >= count; 1 <= count ? i++ : i--) {
        key = randomString(7);
        ks.push(key);
      }
      time = new Date().getTime();
      for (_i = 0, _len = ks.length; _i < _len; _i++) {
        key = ks[_i];
        localCache.set(key, val, 0, function(err, res) {
          assert.isNull(err, err);
        });
      }
      console.log("TIME-SET:", new Date().getTime() - time);
      time = new Date().getTime();
      for (_j = 0, _len2 = ks.length; _j < _len2; _j++) {
        key = ks[_j];
        localCache.get(key, function(err, res) {
          var pred;
          n++;
          pred = {};
          pred[key] = val;
          return assert.eql(pred, res);
        });
      }
      console.log("TIME-GET:", new Date().getTime() - time);
      console.log("MANY STATS:", localCache.getStats());
      return beforeExit(function() {
        return assert.equal(n, count);
      });
    },
    "delete": function(beforeExit, assert) {
      var count, i, n, ri, startKeys;
      n = 0;
      count = 10000;
      startKeys = localCache.getStats().keys;
      for (i = 1; 1 <= count ? i <= count : i >= count; 1 <= count ? i++ : i--) {
        ri = Math.floor(Math.random() * vs.length);
        localCache.del(ks[i], function(err, success) {
          n++;
          assert.isNull(err, err);
          return assert.ok(success);
        });
      }
      for (i = 1; 1 <= count ? i <= count : i >= count; 1 <= count ? i++ : i--) {
        ri = Math.floor(Math.random() * vs.length);
        localCache.del(ks[i], function(err, success) {
          n++;
          assert.ok(success);
          return assert.isNull(err, err);
        });
      }
      assert.equal(localCache.getStats().keys, startKeys - count);
      return beforeExit(function() {
        return assert.equal(n, count * 2);
      });
    },
    "ttl": function(beforeExit, assert) {
      var key, key2, n, val;
      val = randomString(20);
      key = randomString(7);
      key2 = randomString(7);
      n = 0;
      localCache.set(key, val, 500, function(err, res) {
        assert.isNull(err, err);
        assert.ok(res);
        return localCache.get(key, function(err, res) {
          var pred;
          assert.isNull(err, err);
          pred = {};
          pred[key] = val;
          return assert.eql(pred, res);
        });
      });
      localCache.set(key2, val, 800, function(err, res) {
        assert.isNull(err, err);
        assert.ok(res);
        return localCache.get(key2, function(err, res) {
          var pred;
          assert.isNull(err, err);
          pred = {};
          pred[key2] = val;
          return assert.eql(pred, res);
        });
      });
      setTimeout(function() {
        ++n;
        return localCache.get(key, function(err, res) {
          var pred;
          assert.isNull(err, err);
          pred = {};
          pred[key] = val;
          return assert.eql(pred, res);
        });
      }, 400);
      setTimeout(function() {
        ++n;
        return localCache.get(key, function(err, res) {
          assert.isNull(err, err);
          return assert.eql({}, res);
        });
      }, 600);
      return setTimeout(function() {
        ++n;
        return localCache.get(key2, function(err, res) {
          var pred;
          assert.isNull(err, err);
          pred = {};
          pred[key2] = val;
          assert.eql(pred, res);
          return assert.eql(pred, res);
        });
      }, 600);
    },
    "stats": function(beforeExit, assert) {
      var count, end, i, key, keys, n, start, val, vals, _ref;
      n = 0;
      start = _.clone(localCache.getStats());
      count = 5;
      keys = [];
      vals = [];
      for (i = 1, _ref = count * 2; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
        key = randomString(7);
        val = randomString(50);
        keys.push(key);
        vals.push(val);
        localCache.set(key, val, 0, function(err, success) {
          n++;
          assert.isNull(err, err);
          return assert.ok(success);
        });
      }
      for (i = 1; 1 <= count ? i <= count : i >= count; 1 <= count ? i++ : i--) {
        localCache.get(keys[i], function(err, res) {
          var pred;
          n++;
          pred = {};
          pred[keys[i]] = vals[i];
          assert.eql(pred, res);
          return assert.isNull(err, err);
        });
        localCache.del(keys[i], function(err, success) {
          n++;
          assert.isNull(err, err);
          return assert.ok(success);
        });
      }
      for (i = 1; 1 <= count ? i <= count : i >= count; 1 <= count ? i++ : i--) {
        localCache.get("xxxx", function(err, res) {
          ++n;
          assert.isNull(err, err);
          return assert.eql({}, res);
        });
      }
      end = localCache.getStats();
      assert.equal(end.hits - start.hits, 5, "hits wrong");
      assert.equal(end.misses - start.misses, 5, "misses wrong");
      assert.equal(end.keys - start.keys, 5, "hits wrong");
      assert.equal(end.ksize - start.ksize, 5 * 7, "hits wrong");
      assert.equal(end.vsize - start.vsize, 5 * 50, "hits wrong");
      return beforeExit(function() {
        return assert.equal(n, count * 5);
      });
    }
  };
}).call(this);
