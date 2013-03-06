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
app.get '/simple', require('./simple.coffee').simple

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

# App.net global timeline example with profiling.
app.get '/profile', require('./profile.coffee').profile

app.listen 3000
console.log 'The Tally sample is listening on port 3000…'


