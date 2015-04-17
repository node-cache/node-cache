(function() {
  var EventEmitter, NodeCache, _,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  _ = require("lodash");

  EventEmitter = require('events').EventEmitter;

  module.exports = NodeCache = (function(superClass) {
    extend(NodeCache, superClass);

    function NodeCache(options) {
      this.options = options != null ? options : {};
      this._error = bind(this._error, this);
      this._getValLength = bind(this._getValLength, this);
      this._getKeyLength = bind(this._getKeyLength, this);
      this._unwrap = bind(this._unwrap, this);
      this._wrap = bind(this._wrap, this);
      this._check = bind(this._check, this);
      this._checkData = bind(this._checkData, this);
      this.close = bind(this.close, this);
      this.flushAll = bind(this.flushAll, this);
      this.getStats = bind(this.getStats, this);
      this.keys = bind(this.keys, this);
      this.ttl = bind(this.ttl, this);
      this.del = bind(this.del, this);
      this.set = bind(this.set, this);
      this.mget = bind(this.mget, this);
      this.get = bind(this.get, this);
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

    NodeCache.prototype.get = function(key, cb) {
      var _ret;
      if ((this.data[key] != null) && this._check(key, this.data[key])) {
        this.stats.hits++;
        _ret = this._unwrap(this.data[key]);
        if (cb != null) {
          cb(null, _ret);
        }
        return _ret;
      } else {
        this.stats.misses++;
        if (cb != null) {
          cb(null, void 0);
        }
        return void 0;
      }
    };

    NodeCache.prototype.mget = function(keys, cb) {
      var _err, i, key, len, oRet;
      if (!_.isArray(keys)) {
        _err = this._error("EKEYSTYPE");
        if (cb != null) {
          cb(_err);
        }
        return _err;
      }
      oRet = {};
      for (i = 0, len = keys.length; i < len; i++) {
        key = keys[i];
        if ((this.data[key] != null) && this._check(key, this.data[key])) {
          this.stats.hits++;
          oRet[key] = this._unwrap(this.data[key]);
        } else {
          this.stats.misses++;
        }
      }
      if (cb != null) {
        cb(null, oRet);
      }
      return oRet;
    };

    NodeCache.prototype.set = function(key, value, ttl, cb) {
      var existend;
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
      this.emit("set", key, value);
      if (cb != null) {
        cb(null, true);
      }
      return true;
    };

    NodeCache.prototype.del = function(keys, cb) {
      var delCount, i, key, len, oldVal;
      if (_.isString(keys)) {
        keys = [keys];
      }
      delCount = 0;
      for (i = 0, len = keys.length; i < len; i++) {
        key = keys[i];
        if (this.data[key] != null) {
          this.stats.vsize -= this._getValLength(this._unwrap(this.data[key]));
          this.stats.ksize -= this._getKeyLength(key);
          this.stats.keys--;
          delCount++;
          oldVal = this.data[key];
          delete this.data[key];
          this.emit("del", key, oldVal.v);
        } else {
          this.stats.misses++;
        }
      }
      if (cb != null) {
        cb(null, delCount);
      }
      return delCount;
    };

    NodeCache.prototype.ttl = function() {
      var arg, args, cb, i, key, len, ttl;
      key = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      for (i = 0, len = args.length; i < len; i++) {
        arg = args[i];
        switch (typeof arg) {
          case "number":
            ttl = arg;
            break;
          case "function":
            cb = arg;
        }
      }
      ttl || (ttl = this.options.stdTTL);
      if (!key) {
        if (cb != null) {
          cb(null, false);
        }
        return false;
      }
      if ((this.data[key] != null) && this._check(key, this.data[key])) {
        if (ttl > 0) {
          this.data[key] = this._wrap(this.data[key].v, ttl);
        } else {
          this.del(key);
        }
        if (cb != null) {
          cb(null, true);
        }
        return true;
      } else {
        if (cb != null) {
          cb(null, false);
        }
        return false;
      }
    };

    NodeCache.prototype.keys = function(cb) {
      var _keys;
      _keys = Object.keys(this.data);
      if (cb != null) {
        cb(null, _keys);
      }
      return _keys;
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
      this.emit("flush");
    };

    NodeCache.prototype.close = function() {
      this._killCheckPeriod();
    };

    NodeCache.prototype._checkData = function(startPeriod) {
      var key, ref, value;
      if (startPeriod == null) {
        startPeriod = true;
      }
      ref = this.data;
      for (key in ref) {
        value = ref[key];
        this._check(key, value);
      }
      if (startPeriod && this.options.checkperiod > 0) {
        this.checkTimeout = setTimeout(this._checkData, this.options.checkperiod * 1000);
      }
    };

    NodeCache.prototype._killCheckPeriod = function() {
      if (this.checkTimeout != null) {
        return clearTimeout(this.checkTimeout);
      }
    };

    NodeCache.prototype._check = function(key, data) {
      if (data.t !== 0 && data.t < Date.now()) {
        this.del(key);
        this.emit("expired", key, this._unwrap(data));
        return false;
      } else {
        return true;
      }
    };

    NodeCache.prototype._wrap = function(value, ttl) {
      var livetime, now, oReturn, ttlMultiplicator;
      now = Date.now();
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
      if (value.v != null) {
        return value.v;
      }
      return null;
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
      } else if (_.isNumber(value)) {
        return 8;
      } else if (_.isObject(value)) {
        return this.options.objectValueSize * _.size(value);
      } else {
        return 0;
      }
    };

    NodeCache.prototype._error = function(type, data, cb) {
      var error;
      if (data == null) {
        data = {};
      }
      error = new Error();
      error.name = type;
      error.errorcode = type;
      error.msg = this._ERRORS[type] || "-";
      error.data = data;
      if (cb && _.isFunction(cb)) {
        cb(error, null);
      } else {
        return error;
      }
    };

    NodeCache.prototype._ERRORS = {
      "ENOTFOUND": "Key not found",
      "EKEYSTYPE": "The keys argument has to be an array."
    };

    return NodeCache;

  })(EventEmitter);

}).call(this);
