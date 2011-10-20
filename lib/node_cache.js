(function() {
  var NodeCache, _, _timeConfig;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  _ = require("underscore");
  _timeConfig = {
    types: ["ms", "s", "m", "h", "d"],
    multiConfig: [1, 1000, 60, 60, 24]
  };
  _timeConfig.multi = _.reduce(_timeConfig.multiConfig, function(v1, v2, idx, ar) {
    v1.push((v1[idx - 1] || 1) * v2);
    return v1;
  }, []);
  module.exports = NodeCache = (function() {
    function NodeCache(options) {
      this.options = options != null ? options : {};
      this._getMilliSeconds = __bind(this._getMilliSeconds, this);
      this._error = __bind(this._error, this);
      this._check = __bind(this._check, this);
      this._getValLength = __bind(this._getValLength, this);
      this._getKeyLength = __bind(this._getKeyLength, this);
      this._unwrap = __bind(this._unwrap, this);
      this._wrap = __bind(this._wrap, this);
      this.checkData = __bind(this.checkData, this);
      this.getStats = __bind(this.getStats, this);
      this.del = __bind(this.del, this);
      this.set = __bind(this.set, this);
      this.data = {};
      this.options = _.extend({
        forceString: true,
        objectValueSize: 80,
        arrayValueSize: 40,
        stdTTL: 0
      }, this.options);
      this.stats = {
        hits: 0,
        misses: 0,
        keys: 0,
        ksize: 0,
        vsize: 0
      };
    }
    NodeCache.prototype.get = function(key, cb) {
      var oRet;
      if ((this.data[key] != null) && this._check(key, this.data[key])) {
        this.stats.hits++;
        oRet = {};
        oRet[key] = this._unwrap(this.data[key]);
        cb(null, oRet);
      } else {
        this.stats.misses++;
        cb(null, {});
      }
    };
    NodeCache.prototype.set = function(key, value, ttl, cb) {
      var existend;
      existend = false;
      if (this.options.forceString && !_.isString(value)) {
        value = JSON.stringify(value);
      }
      if (arguments.length === 3) {
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
    NodeCache.prototype.del = function(key, cb) {
      if (cb == null) {
        cb = function() {};
      }
      if (this.data[key] != null) {
        this.stats.vsize -= this._getValLength(this._unwrap(this.data[key]));
        this.stats.ksize -= this._getKeyLength(key);
        this.stats.keys--;
        delete this.data[key];
        cb(null, true);
      } else {
        this.stats.misses++;
        cb(null, true);
      }
    };
    NodeCache.prototype.getStats = function() {
      return this.stats;
    };
    NodeCache.prototype.checkData = function() {
      var key, value, _ref;
      _ref = this.data;
      for (key in _ref) {
        value = _ref[key];
        this._check(key, vData);
      }
    };
    NodeCache.prototype._wrap = function(value, ttl) {
      var livetime, oReturn;
      livetime = 0;
      if (ttl === 0) {
        livetime = 0;
      } else if (ttl) {
        livetime = new Date().getTime() + this._getMilliSeconds(ttl);
      } else {
        livetime = this.options.stdTTL;
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
    NodeCache.prototype._getMilliSeconds = function(time) {
      var iType, type;
      iType = -1;
      if (_.isString(time)) {
        type = time.replace(/\d+/gi, '');
        time = parseInt(time.replace(/\D+/gi, ''), 10);
        iType = _timeConfig.types.indexOf(type);
      }
      if (iType >= 0) {
        return time * _timeConfig.multi[iType];
      } else if (isNaN(time)) {
        return null;
      } else {
        return time;
      }
    };
    return NodeCache;
  })();
}).call(this);
