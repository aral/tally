################################################################################
#
# Tally examples.
#
# The server for the Tally examples.
#
# Copyright © 2013, Aral Balkan.
# Released under the MIT license. (http://opensource.org/licenses/MIT)
#
################################################################################

express = require 'express'
tally = require './lib/tally-express.coffee'

superagent = require 'superagent'

# Helper: create a route from a route name (e.g., /simple -> /routes/simple.coffee)
createRoute = (routeName) ->
	route = require('./routes/' + if routeName == '/' then 'index' else routeName[1..] + '.coffee').route
	app.get routeName, route

#
# Set up Express with Tally as the templating engine.
#
app = express()
app.engine 'html', (require './lib/tally-express.coffee').__express
app.set 'view engine', 'html'
app.set 'views', __dirname + '/views'
app.use express.static('views')

createRoute '/'

# Simple template example (with static data)
createRoute '/simple'

# App.net global timeline example.
createRoute '/posts'

# App.net global timeline example with profiling.
createRoute '/profile'

app.listen 3000

console.log '\nServer running… visit http://localhost:3000/ to play with the Tally examples.\n'


