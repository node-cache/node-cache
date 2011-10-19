(function() {
  var VariableCache;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  module.exports = VariableCache = (function() {
    function VariableCache(options) {
      this.options = options != null ? options : {};
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
    VariableCache.prototype.get = function(key, cb) {
      if ((this.data[key] != null) && this._check(key, this.data[key])) {
        this.stats.hits++;
        cb(null, this._unwrap(this.data[key]));
      } else {
        this.stats.misses++;
        this._error('not-found', {
          method: "get"
        }, cb);
      }
    };
    VariableCache.prototype.set = function(key, value, ttl, cb) {
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
        this.stats.vsize -= this._getValLength(this._unwrap(data[key]));
      }
      this.data[key] = this._wrap(value);
      this.stats.vsize += this._getValLength(value);
      if (!existend) {
        this.stats.ksize += this._getKeyLength(key);
        this.stats.keys++;
      }
      cb(cb, true);
    };
    VariableCache.prototype.del = function(key, cb) {
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
        this._error('not-found', {
          method: "dl"
        }, cb);
      }
    };
    VariableCache.prototype.getStats = function() {
      return this.stats;
    };
    VariableCache.prototype.checkData = function() {
      var key, value, _ref;
      _ref = this.data;
      for (key in _ref) {
        value = _ref[key];
        this._check(key, vData);
      }
    };
    VariableCache.prototype._wrap = function(value, ttl) {
      var livetime, oReturn;
      if (ttl == null) {
        ttl = this.options.stdTTL;
      }
      if (ttl) {
        livetime = new Date().getTime() + utils.getMilliSeconds(ttl);
      }
      return oReturn = {
        t: livetime,
        v: value
      };
    };
    VariableCache.prototype._unwrap = function(value) {
      return value.v || null;
    };
    VariableCache.prototype._getKeyLength = function(key) {
      return key.length;
    };
    VariableCache.prototype._getValLength = function(value) {
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
    VariableCache.prototype._check = function(key, data) {
      var now;
      now = new Date().getTime();
      if (data.t < now && date.t !== 0) {
        this.del(key);
        return false;
      } else {
        return true;
      }
    };
    VariableCache.prototype._error = function(type, data, cb) {
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
    return VariableCache;
  })();
}).call(this);
