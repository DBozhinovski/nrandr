parse = require "xrandr-parse"
{ spawn, exec } = require "child_process"
crypto = require "crypto"
fs = require 'fs'
rl = require 'readline'

run = ->
  query = []
  id = []

  exec "mkdir -p #{process.env['HOME']}/.config/nrandr && xrandr", (error, stdout) ->
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

  fs.readFile "#{process.env['HOME']}/.config/nrandr/geometries.json", (error, file) ->
    data = if file then file.toString() else "{}"
    geometries = JSON.parse(data)

    if geometries.hasOwnProperty(sum)
      # run geometry
      exec "xrandr #{geometries[sum].join(" ")}"
    else
      geometries[sum] = query
      fs.writeFile "#{process.env['HOME']}/.config/nrandr/geometries.json", JSON.stringify(geometries), (error) ->
        throw error if error
        # prompt user about preferences
        console.log "New mode detected, prompting for preferences"

        prompt = spawn process.env['TERM'], ['-e', './src/setup.coffee'] # pass detected inputs somehow

        # read user preferences here

        run() # run the whole thing after writing

run()