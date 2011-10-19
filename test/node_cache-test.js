(function() {
  var VCache, ks, localCache, randomString, vs;
  root._ = require("../node_modules/underscore");
  root.utils = require("../lib/utils");
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
    "test node_cache#general": function(beforeExit, assert) {
      var done, key, value;
      done = false;
      value = randomString(100);
      key = randomString(10);
      localCache.set(key, value, 0, function(err, res) {
        return localCache.get(key, function(err, res) {
          done = true;
          assert.equal(value, res);
          return console.log("general stats:", localCache.getStats());
        });
      });
      return beforeExit(function() {
        return assert.equal(true, done, "not exited");
      });
    },
    "test node_cache#many": function(beforeExit, assert) {
      var count, i, key, n, time, val, _i, _j, _len, _len2;
      n = 0;
      count = 1000000;
      val = randomString(20);
      for (i = 1; 1 <= count ? i <= count : i >= count; 1 <= count ? i++ : i--) {
        key = randomString(7);
        ks.push(key);
      }
      time = new Date().getTime();
      for (_i = 0, _len = ks.length; _i < _len; _i++) {
        key = ks[_i];
        localCache.set(key, val, 0, function(err, res) {});
      }
      console.log("time:", new Date().getTime() - time);
      for (_j = 0, _len2 = ks.length; _j < _len2; _j++) {
        key = ks[_j];
        localCache.get(key, function(err, res) {
          n++;
          return assert.equal(val, res);
        });
      }
      console.log("time:", new Date().getTime() - time);
      console.log("general stats:", localCache.getStats());
      return beforeExit(function() {
        return assert.equal(n, count);
      });
    },
    "test node_cache#delete": function(beforeExit, assert) {
      var count, i, n, ri, startKeys, time;
      time = new Date().getTime();
      n = 0;
      count = 10000;
      startKeys = localCache.getStats().keys;
      for (i = 1; 1 <= count ? i <= count : i >= count; 1 <= count ? i++ : i--) {
        ri = Math.floor(Math.random() * vs.length);
        localCache.del(ks[i], function(err, success) {
          n++;
          assert.equal(true, success);
          return assert.isNull(err, err);
        });
      }
      console.log("time:", new Date().getTime() - time);
      console.log("general stats:", localCache.getStats());
      return beforeExit(function() {
        assert.equal(n, count);
        return assert.equal(localCache.getStats().keys, startKeys - n);
      });
    }
  };
}).call(this);
