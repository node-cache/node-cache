(function() {
  var VCache, _, ks, localCache, localCacheTTL, randomString, vs,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  _ = require("lodash");

  VCache = require("../");

  localCache = new VCache({
    stdTTL: 0
  });

  localCacheTTL = new VCache({
    stdTTL: 0.3,
    checkperiod: 0
  });

  localCache._killCheckPeriod();

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
      console.log("\nSTART GENERAL TEST: " + VCache.version);
      n = 0;
      start = _.clone(localCache.getStats());
      value = randomString(100);
      value2 = randomString(100);
      key = randomString(10);
      localCache.once("del", function(_key, _val) {
        assert.equal(_key, key);
        assert.equal(_val, value2);
      });
      localCache.set(key, value, 0, function(err, res) {
        assert.isNull(err, err);
        n++;
        assert.equal(1, localCache.getStats().keys - start.keys);
        localCache.get(key, function(err, res) {
          n++;
          assert.eql(value, res);
        });
        localCache.keys(function(err, res) {
          var pred;
          n++;
          pred = [key];
          assert.eql(pred, res);
        });
        localCache.get("xxx", function(err, res) {
          n++;
          assert.isNull(err, err);
          assert.isUndefined(res, res);
        });
        localCache.del("xxx", function(err, res) {
          n++;
          assert.isNull(err, err);
          assert.equal(0, res);
        });
        localCache.set(key, value2, 0, function(err, res) {
          n++;
          assert.isNull(err, err);
          assert.ok(res, err);
          localCache.get(key, function(err, res) {
            var pred;
            n++;
            pred = value2;
            assert.eql(pred, res);
            assert.equal(1, localCache.getStats().keys - start.keys);
          });
        });
        localCache.del(key, function(err, res) {
          localCache.removeAllListeners("del");
          n++;
          assert.isNull(err, err);
          assert.equal(1, res);
          assert.equal(0, localCache.getStats().keys - start.keys);
          localCache.get(key, function(err, res) {
            n++;
            assert.isNull(err, err);
            assert.isUndefined(res, res);
          });
          localCache.set("zero", 0, 0, function(err, res) {
            n++;
            assert.isNull(err, err);
            assert.ok(res, err);
          });
          localCache.get("zero", function(err, res) {
            n++;
            assert.isNull(err, err);
            assert.eql(0, res);
          });
        });
      });
      beforeExit(function() {
        assert.equal(11, n, "not exited");
      });
    },
    "general sync": function(beforeExit, assert) {
      var key, pred, res, start, value, value2;
      console.log("\nSTART GENERAL TEST SYNC");
      localCache.flushAll();
      start = _.clone(localCache.getStats());
      value = randomString(100);
      value2 = randomString(100);
      key = randomString(10);
      localCache.once("del", function(_key, _val) {
        assert.equal(_key, key);
        assert.equal(_val, value2);
      });
      assert.ok(localCache.set(key, value, 0));
      assert.equal(1, localCache.getStats().keys - start.keys);
      res = localCache.get(key);
      assert.eql(value, res);
      res = localCache.keys();
      pred = [key];
      assert.eql(pred, res);
      res = localCache.get("xxx");
      assert.isUndefined(res, res);
      res = localCache.del("xxx");
      assert.equal(0, res);
      res = localCache.set(key, value2, 0);
      assert.ok(res, res);
      res = localCache.get(key);
      assert.eql(value2, res);
      assert.equal(1, localCache.getStats().keys - start.keys);
      res = localCache.del(key);
      localCache.removeAllListeners("del");
      assert.equal(1, res);
      assert.equal(0, localCache.getStats().keys - start.keys);
      res = localCache.get(key);
      assert.isUndefined(res, res);
      res = localCache.set("zero", 0, 0);
      assert.ok(res, res);
      res = localCache.get("zero");
      assert.eql(0, res);
    },
    "flush": function(beforeExit, assert) {
      var count, i, j, k, key, len, n, ref, startKeys, val;
      console.log("\nSTART FLUSH TEST");
      n = 0;
      count = 100;
      startKeys = localCache.getStats().keys;
      ks = [];
      val = randomString(20);
      for (i = j = 1, ref = count; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
        key = randomString(7);
        ks.push(key);
      }
      for (k = 0, len = ks.length; k < len; k++) {
        key = ks[k];
        localCache.set(key, val, 0, function(err, res) {
          n++;
          assert.isNull(err, err);
        });
      }
      assert.equal(localCache.getStats().keys, startKeys + count);
      localCache.flushAll(false);
      assert.equal(localCache.getStats().keys, 0);
      assert.eql(localCache.data, {});
      beforeExit(function() {
        assert.equal(n, count + 0);
      });
    },
    "many": function(beforeExit, assert) {
      var _dur, count, i, j, k, key, l, len, len1, n, ref, time, val;
      n = 0;
      count = 100000;
      console.log("\nSTART MANY TEST/BENCHMARK.\nSet, Get and check " + count + " elements");
      val = randomString(20);
      ks = [];
      for (i = j = 1, ref = count; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
        key = randomString(7);
        ks.push(key);
      }
      time = new Date().getTime();
      for (k = 0, len = ks.length; k < len; k++) {
        key = ks[k];
        assert.ok(localCache.set(key, val, 0));
      }
      _dur = new Date().getTime() - time;
      console.log("BENCHMARK for SET:", _dur + "ms", " ( " + (_dur / count) + "ms per item ) ");
      time = new Date().getTime();
      for (l = 0, len1 = ks.length; l < len1; l++) {
        key = ks[l];
        n++;
        assert.eql(val, localCache.get(key));
      }
      _dur = new Date().getTime() - time;
      console.log("BENCHMARK for GET:", _dur + "ms", " ( " + (_dur / count) + "ms per item ) ");
      console.log("BENCHMARK STATS:", localCache.getStats());
      beforeExit(function() {
        var _keys, _stats;
        _stats = localCache.getStats();
        _keys = localCache.keys();
        assert.eql(_stats.keys, _keys.length);
        console.log(_stats);
        assert.eql(count - 10000 + 100, _keys.length);
        assert.equal(n, count);
      });
    },
    "delete": function(beforeExit, assert) {
      var count, i, j, k, n, ref, ref1, ri, startKeys;
      console.log("\nSTART DELETE TEST");
      n = 0;
      count = 10000;
      startKeys = localCache.getStats().keys;
      for (i = j = 1, ref = count; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
        ri = Math.floor(Math.random() * vs.length);
        localCache.del(ks[i], function(err, count) {
          n++;
          assert.isNull(err, err);
          return assert.equal(1, count);
        });
      }
      for (i = k = 1, ref1 = count; 1 <= ref1 ? k <= ref1 : k >= ref1; i = 1 <= ref1 ? ++k : --k) {
        ri = Math.floor(Math.random() * vs.length);
        localCache.del(ks[i], function(err, count) {
          n++;
          assert.equal(0, count);
          return assert.isNull(err, err);
        });
      }
      assert.equal(localCache.getStats().keys, startKeys - count);
      beforeExit(function() {
        assert.equal(n, count * 2);
      });
    },
    "stats": function(beforeExit, assert) {
      var count, end, i, j, k, key, keys, l, n, ref, ref1, ref2, start, val, vals;
      console.log("\nSTART STATS TEST");
      n = 0;
      start = _.clone(localCache.getStats());
      count = 5;
      keys = [];
      vals = [];
      for (i = j = 1, ref = count * 2; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
        key = randomString(7);
        val = randomString(50);
        keys.push(key);
        vals.push(val);
        localCache.set(key, val, 0, function(err, success) {
          n++;
          assert.isNull(err, err);
          assert.ok(success);
        });
      }
      for (i = k = 1, ref1 = count; 1 <= ref1 ? k <= ref1 : k >= ref1; i = 1 <= ref1 ? ++k : --k) {
        localCache.get(keys[i], function(err, res) {
          n++;
          assert.eql(vals[i], res);
          assert.isNull(err, err);
        });
        localCache.del(keys[i], function(err, success) {
          n++;
          assert.isNull(err, err);
          assert.ok(success);
        });
      }
      for (i = l = 1, ref2 = count; 1 <= ref2 ? l <= ref2 : l >= ref2; i = 1 <= ref2 ? ++l : --l) {
        localCache.get("xxxx", function(err, res) {
          ++n;
          assert.isNull(err, err);
          assert.isUndefined(res, res);
        });
      }
      end = localCache.getStats();
      assert.equal(end.hits - start.hits, 5, "hits wrong");
      assert.equal(end.misses - start.misses, 5, "misses wrong");
      assert.equal(end.keys - start.keys, 5, "hits wrong");
      assert.equal(end.ksize - start.ksize, 5 * 7, "hits wrong");
      assert.equal(end.vsize - start.vsize, 5 * 50, "hits wrong");
      beforeExit(function() {
        assert.equal(n, count * 5);
      });
    },
    "multi": function(beforeExit, assert) {
      var count, getKeys, i, j, k, key, l, len, len1, n, pred, ref, startKeys, val;
      console.log("\nSTART MULTI TEST");
      n = 0;
      count = 100;
      startKeys = localCache.getStats().keys;
      ks = [];
      val = randomString(20);
      for (i = j = 1, ref = count; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
        key = randomString(7);
        ks.push(key);
      }
      for (k = 0, len = ks.length; k < len; k++) {
        key = ks[k];
        localCache.set(key, val, 0, function(err, res) {
          n++;
          assert.isNull(err, err);
        });
      }
      getKeys = ks.splice(50, 5);
      pred = {};
      for (l = 0, len1 = getKeys.length; l < len1; l++) {
        key = getKeys[l];
        pred[key] = val;
      }
      localCache.mget(getKeys[0], function(err, res) {
        n++;
        assert.isNotNull(err, err);
        assert.eql(err.constructor.name, "Error");
        assert.eql("EKEYSTYPE", err.name);
        assert.isUndefined(res, res);
      });
      localCache.mget(getKeys, function(err, res) {
        n++;
        assert.isNull(err, err);
        assert.eql(pred, res);
      });
      localCache.del(getKeys, function(err, res) {
        n++;
        assert.isNull(err, err);
        assert.equal(getKeys.length, res);
      });
      localCache.mget(getKeys, function(err, res) {
        n++;
        assert.isNull(err, err);
        assert.eql({}, res);
      });
      beforeExit(function() {
        assert.equal(n, count + 4);
      });
    },
    "ttl": function(beforeExit, assert) {
      var _keys, key, key2, key3, key4, key5, n, val;
      console.log("\nSTART TTL TEST");
      val = randomString(20);
      key = "k1_" + randomString(7);
      key2 = "k2_" + randomString(7);
      key3 = "k3_" + randomString(7);
      key4 = "k4_" + randomString(7);
      key5 = "k5_" + randomString(7);
      _keys = [key, key2, key3, key4, key5];
      n = 0;
      localCache.set(key, val, 0.5, function(err, res) {
        assert.isNull(err, err);
        assert.ok(res);
        localCache.get(key, function(err, res) {
          assert.isNull(err, err);
          assert.eql(val, res);
        });
      });
      localCache.set(key2, val, 0.3, function(err, res) {
        assert.isNull(err, err);
        assert.ok(res);
        localCache.get(key2, function(err, res) {
          assert.isNull(err, err);
          assert.eql(val, res);
        });
      });
      setTimeout(function() {
        ++n;
        localCache.get(key, function(err, res) {
          assert.isNull(err, err);
          assert.eql(val, res);
        });
      }, 400);
      setTimeout(function() {
        ++n;
        localCache.get(key, function(err, res) {
          assert.isNull(err, err);
          assert.isUndefined(res, res);
        });
      }, 600);
      setTimeout(function() {
        ++n;
        localCache.get(key2, function(err, res) {
          assert.isNull(err, err);
          assert.eql(val, res);
        });
      }, 250);
      setTimeout(function() {
        process.nextTick(function() {
          var _testExpired, _testSet, startKeys;
          startKeys = localCache.getStats().keys;
          key = "autotest";
          _testExpired = (function(_this) {
            return function(_key, _val) {
              if (indexOf.call(_keys, _key) < 0) {
                assert.equal(_key, key);
                assert.equal(_val, val);
              }
            };
          })(this);
          _testSet = (function(_this) {
            return function(_key) {
              assert.equal(_key, key);
            };
          })(this);
          localCache.once("set", _testSet);
          localCache.set(key, val, 0.5, function(err, res) {
            assert.isNull(err, err);
            assert.ok(res);
            assert.equal(startKeys + 1, localCache.getStats().keys);
            localCache.get(key, function(err, res) {
              assert.eql(val, res);
              localCache.on("expired", _testExpired);
              return setTimeout(function() {
                localCache._checkData(false);
                assert.isUndefined(localCache.data[key]);
                localCache.removeAllListeners("set");
                localCache.removeAllListeners("expired");
              }, 700);
            });
          });
        });
      }, 1000);
      localCache.set(key3, val, 100, function(err, res) {
        assert.isNull(err, err);
        assert.ok(res);
        localCache.get(key3, function(err, res) {
          assert.isNull(err, err);
          assert.eql(val, res);
          localCache.ttl(key3 + "false", 0.3, function(err, setted) {
            assert.isNull(err, err);
            assert.equal(false, setted);
          });
          localCache.ttl(key3, 0.3, function(err, setted) {
            assert.isNull(err, err);
            assert.ok(setted);
          });
          localCache.get(key3, function(err, res) {
            assert.eql(val, res);
          });
          setTimeout(function() {
            res = localCache.get(key3);
            assert.isUndefined(res, res);
            assert.isUndefined(localCache.data[key3]);
          }, 500);
        });
      });
      localCache.set(key4, val, 100, function(err, res) {
        assert.isNull(err, err);
        assert.ok(res);
        localCache.get(key4, function(err, res) {
          assert.isNull(err, err);
          assert.eql(val, res);
          localCache.ttl(key4 + "false", function(err, setted) {
            assert.isNull(err, err);
            return assert.equal(false, setted);
          });
          localCache.ttl(key4, function(err, setted) {
            assert.isNull(err, err);
            assert.ok(setted);
            assert.isUndefined(localCache.data[key4]);
          });
        });
      });
      localCacheTTL.set(key5, val, 100, function(err, res) {
        assert.isNull(err, err);
        assert.ok(res);
        localCacheTTL.get(key5, function(err, res) {
          assert.isNull(err, err);
          assert.eql(val, res);
          localCacheTTL.ttl(key5 + "false", function(err, setted) {
            assert.isNull(err, err);
            assert.equal(false, setted);
          });
          localCacheTTL.ttl(key5, function(err, setted) {
            assert.isNull(err, err);
            assert.ok(setted);
          });
          localCacheTTL.get(key5, function(err, res) {
            assert.eql(val, res);
          });
          setTimeout(function() {
            res = localCache.get(key5);
            assert.isUndefined(res, res);
            localCacheTTL._checkData(false);
            assert.isUndefined(localCacheTTL.data[key5]);
          }, 500);
        });
      });
    }
  };

}).call(this);
