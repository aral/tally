express = require 'express'
tally = require './lib/tally.coffee'

# Sample data
data =
    title: 'Tally sample'
    name: 'Tally'
    content: 'This is a simple example to demonstrate Tally, a templating engine for Express 3 that uses Distal, a JavaScript implementation of TAL from the Zope framework.'
    newURL: 'http://aralbalkan.com'
    correctURLFragment: 'moderniosdevelopment'
    aralImageURL: 'http://aralbalkan.com/images/aral.jpg'
    friends:
        [
            {name: 'Laura', skills: 'design, development, illustration, speaking'},
            {name: 'Seb', skills: 'particles, games, JavaScript, C++'},
            {name: 'Natalie', skills: 'HTML, CSS'}
        ]

#
# Set up Express with Tally as the templating engine.
#
app = express()
app.engine 'html', tally.__express
app.set 'views', __dirname + '/views'

# Pure Tally call.
app.get '/', (request, response) ->
    data.hybrid = no
    response.render 'index.html', data

# Hybrid Tally call.
app.get '/hybrid', (request, response) ->
    data.hybrid = yes
    response.render 'hybrid.html', data

app.listen 3000
console.log 'Express-Tally is listening on port 3000…'


