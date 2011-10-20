(function() {
  var _timeConfig;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  _timeConfig = {
    types: ["ms", "s", "m", "h", "d"],
    multiConfig: [1, 1000, 60, 60, 24]
  };
  _timeConfig.multi = _.reduce(_timeConfig.multiConfig, function(v1, v2, idx, ar) {
    v1.push((v1[idx - 1] || 1) * v2);
    return v1;
  }, []);
  module.exports = {
    getMilliSeconds: __bind(function(time) {
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
    }, this)
  };
}).call(this);
