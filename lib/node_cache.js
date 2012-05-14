(function() {
  var NodeCache, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;
  _ = require("underscore");
  module.exports = NodeCache = (function() {
    function NodeCache(options) {
      this.options = options != null ? options : {};
      this._error = __bind(this._error, this);
      this._getValLength = __bind(this._getValLength, this);
      this._getKeyLength = __bind(this._getKeyLength, this);
      this._unwrap = __bind(this._unwrap, this);
      this._wrap = __bind(this._wrap, this);
      this._check = __bind(this._check, this);
      this._checkData = __bind(this._checkData, this);
      this.flushAll = __bind(this.flushAll, this);
      this.getStats = __bind(this.getStats, this);
      this.ttl = __bind(this.ttl, this);
      this.del = __bind(this.del, this);
      this.set = __bind(this.set, this);
      this.get = __bind(this.get, this);
      this.data = {};
      this.options = _.extend({
        forceString: false,
        objectValueSize: 80,
        arrayValueSize: 40,
        stdTTL: 0,
        checkperiod: 600
      }, this.options);
      this.stats = {
        hits: 0,
        misses: 0,
        keys: 0,
        ksize: 0,
        vsize: 0
      };
      this._checkData();
    }
    NodeCache.prototype.get = function(keys, cb) {
      var key, oRet, _i, _len;
      if (_.isString(keys)) {
        keys = [keys];
      }
      oRet = {};
      for (_i = 0, _len = keys.length; _i < _len; _i++) {
        key = keys[_i];
        if ((this.data[key] != null) && this._check(key, this.data[key])) {
          this.stats.hits++;
          oRet[key] = this._unwrap(this.data[key]);
        } else {
          this.stats.misses++;
        }
      }
      cb(null, oRet);
    };
    NodeCache.prototype.set = function(key, value, ttl, cb) {
      var existend;
      if (cb == null) {
        cb = function() {};
      }
      existend = false;
      if (this.options.forceString && !_.isString(value)) {
        value = JSON.stringify(value);
      }
      if (arguments.length === 3 && _.isFunction(ttl)) {
        cb = ttl;
        ttl = this.options.stdTTL;
      }
      if (this.data[key]) {
        existend = true;
        this.stats.vsize -= this._getValLength(this._unwrap(this.data[key]));
      }
      this.data[key] = this._wrap(value, ttl);
      this.stats.vsize += this._getValLength(value);
      if (!existend) {
        this.stats.ksize += this._getKeyLength(key);
        this.stats.keys++;
      }
      cb(null, true);
    };
    NodeCache.prototype.del = function(keys, cb) {
      var delCount, key, _i, _len;
      if (cb == null) {
        cb = function() {};
      }
      if (_.isString(keys)) {
        keys = [keys];
      }
      delCount = 0;
      for (_i = 0, _len = keys.length; _i < _len; _i++) {
        key = keys[_i];
        if (this.data[key] != null) {
          this.stats.vsize -= this._getValLength(this._unwrap(this.data[key]));
          this.stats.ksize -= this._getKeyLength(key);
          this.stats.keys--;
          delCount++;
          delete this.data[key];
        } else {
          this.stats.misses++;
        }
      }
      cb(null, delCount);
    };
    NodeCache.prototype.ttl = function() {
      var arg, args, cb, key, ttl, _i, _len;
      key = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      for (_i = 0, _len = args.length; _i < _len; _i++) {
        arg = args[_i];
        switch (typeof arg) {
          case "number":
            ttl = arg;
            break;
          case "function":
            cb = arg;
        }
      }
      cb || (cb = function() {});
      ttl || (ttl = this.options.stdTTL);
      if (!key) {
        cb(null, false);
      }
      if ((this.data[key] != null) && this._check(key, this.data[key])) {
        if (ttl > 0) {
          this.data[key] = this._wrap(this.data[key].v, ttl);
        } else {
          this.del(key);
        }
        cb(null, true);
      } else {
        cb(null, false);
      }
    };
    NodeCache.prototype.getStats = function() {
      return this.stats;
    };
    NodeCache.prototype.flushAll = function(_startPeriod) {
      if (_startPeriod == null) {
        _startPeriod = true;
      }
      this.data = {};
      this.stats = {
        hits: 0,
        misses: 0,
        keys: 0,
        ksize: 0,
        vsize: 0
      };
      this._killCheckPeriod();
      this._checkData(_startPeriod);
    };
    NodeCache.prototype._checkData = function(startPeriod) {
      var key, value, _ref;
      if (startPeriod == null) {
        startPeriod = true;
      }
      _ref = this.data;
      for (key in _ref) {
        value = _ref[key];
        this._check(key, value);
      }
      if (startPeriod) {
        this.checkTimeout = setTimeout(this._checkData, this.options.checkperiod * 1000);
      }
    };
    NodeCache.prototype._killCheckPeriod = function() {
      if (this.checkTimeout != null) {
        return clearTimeout(this.checkTimeout);
      }
    };
    NodeCache.prototype._check = function(key, data) {
      var now;
      now = new Date().getTime();
      if (data.t < now && data.t !== 0) {
        this.del(key);
        return false;
      } else {
        return true;
      }
    };
    NodeCache.prototype._wrap = function(value, ttl) {
      var livetime, now, oReturn, ttlMultiplicator;
      now = new Date().getTime();
      livetime = 0;
      ttlMultiplicator = 1000;
      if (ttl === 0) {
        livetime = 0;
      } else if (ttl) {
        livetime = now + (ttl * ttlMultiplicator);
      } else {
        if (this.options.stdTTL === 0) {
          livetime = this.options.stdTTL;
        } else {
          livetime = now + (this.options.stdTTL * ttlMultiplicator);
        }
      }
      return oReturn = {
        t: livetime,
        v: value
      };
    };
    NodeCache.prototype._unwrap = function(value) {
      return value.v || null;
    };
    NodeCache.prototype._getKeyLength = function(key) {
      return key.length;
    };
    NodeCache.prototype._getValLength = function(value) {
      if (_.isString(value)) {
        return value.length;
      } else if (this.options.forceString) {
        return JSON.stringify(value).length;
      } else if (_.isArray(value)) {
        return this.options.arrayValueSize * value.length;
      } else {
        return this.options.objectValueSize * _.size(value);
      }
    };
    NodeCache.prototype._error = function(type, data, cb) {
      var error;
      if (data == null) {
        data = {};
      }
      error = {
        errorcode: type,
        msg: "-",
        data: data
      };
      if (cb && _.isFunction(cb)) {
        cb(error, null);
      } else {
        return error;
      }
    };
    return NodeCache;
  })();
}).call(this);
