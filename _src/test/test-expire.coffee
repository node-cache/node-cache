NodeCache = require('../')
queriesCache = new NodeCache({ stdTTL: 2, checkperiod: 1 })

idx = 0
_write = ->
	console.log "test - WRITE:A query:#{idx}"
	queriesCache.set "query", idx, ( err, success )->
		console.log "test - WRITE:B query:#{idx}", err, success
		idx++
		return
	return

_read = ->
	console.log "test - read:A query"
	queriesCache.get "query", ( err, value )->
		if value[ "query" ]?
			console.log "test - read:B query:#{value[ "query" ]}"
		else
			console.log "test - !! EMPTY !! - read:B query:#{value[ "query" ]}"
		return
	return

queriesCache.on "expired", ( key, value )->
	console.log "test - EXPIRED query:#{value}"
	_write()
	return

_write()

setInterval( _read, 600 )
#setInterval( _read, 200 )
#setInterval( _read, 100 )