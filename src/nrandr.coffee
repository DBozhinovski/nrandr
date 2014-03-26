parse = require "xrandr-parse"
{ exec } = require "child_process"
crypto = require "crypto"
fs = require 'fs'

query = []
id = []

run = ->
  exec 'xrandr', (error, stdout) ->
    outputs = parse stdout
    for output, params of outputs
      if params.connected
        id.push output
        query.push "--output #{output} --auto"

    getGeometry id, query

getGeometry = (id, query) ->
  md5sum = crypto.createHash 'md5'
  md5sum.update id.join('-')
  sum = md5sum.digest('hex')

  fs.readFile './geometries.json', (error, file) ->
    geometries = JSON.parse file.toString()
    if geometries.hasOwnProperty(sum)
      # run geometry
      exec "xrandr #{geometries[sum].join(" ")}"
    else
      geometries[sum] = query
      console.log "New mode detected, written to geometries"
      fs.writeFile './geometries.json', JSON.stringify(geometries), (error) ->
        run() # run the whole thing after writing

run()