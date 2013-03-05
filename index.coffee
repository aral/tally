express = require 'express'
tally = require './lib/tally-express.coffee'

superagent = require 'superagent'

#
# Set up Express with Tally as the templating engine.
#
app = express()
app.engine 'html', tally.__express
app.set 'views', __dirname + '/views'
app.use express.static('views')

#
# Simple template example (with static data)
#

# Sample data
data =
    title: 'Tally sample'
    name: 'Tally'
    content: 'This is a simple example to demonstrate Tally, a templating engine for Express 3 and client‐side JavaScript built on Distal, a JavaScript implementation of TAL from the Zope framework.'
    newURL: 'http://aralbalkan.com'
    correctURLFragment: 'moderniosdevelopment'
    aralImageURL: 'http://aralbalkan.com/images/aral.jpg'
    friends:
        [
            {name: 'Laura', skills: 'design, development, illustration, speaking'},
            {name: 'Seb', skills: 'particles, games, JavaScript, C++'},
            {name: 'Natalie', skills: 'HTML, CSS'}
        ]

# Pure Tally call.
app.get '/', (request, response) ->
    data.hybrid = no
    response.render 'index.html', data

# Hybrid Tally call.
app.get '/hybrid', (request, response) ->
    data.hybrid = yes
    response.render 'hybrid.html', data

#
# App.net global timeline example.
#

app.get '/posts', (request, response) ->
    superagent.get('https://alpha-api.app.net/stream/0/posts/stream/global')
        .end (globalTimelineResponse) ->
            if globalTimelineResponse.body

                # Attach a custom function to the data to count the number of posts
                globalTimelineResponse.body.numberOfPosts = ->
                    return this.data.length

                response.render 'posts.html', globalTimelineResponse.body
            else
                response.render 'posts.html', {error: 'Bad response from Twitter'}


app.listen 3000
console.log 'The Tally sample is listening on port 3000…'


