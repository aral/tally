superagent = require 'superagent'
timer = require './lib/timer.coffee'

exports.profile = (request, response) ->

    # Time the data call
    timer.reset()

    superagent.get('https://alpha-api.app.net/stream/0/posts/stream/global')
        .end (globalTimelineResponse) ->

            timer.elapsedTime('Data transfer from App.net')

            if globalTimelineResponse.body

                # Attach a custom function to the data to count the number of posts
                globalTimelineResponse.body.numberOfPosts = ->
                    return this.data.length

                # Time the template render
                timer.reset()
                response.render 'posts.html', globalTimelineResponse.body
                timer.elapsedTime('Template render')

            else
                response.render 'posts.html', {error: 'Bad response from Twitter'}
