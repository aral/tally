################################################################################
#
# Tally App.net posts example (with timer profiling)
#
# Displays the global timeline from App.net and profiles the template render.
#
# Copyright © 2013, Aral Balkan.
# Released under the MIT license. (http://opensource.org/licenses/MIT)
#
################################################################################

superagent = require 'superagent'
timer = require '../lib/timer.coffee'

exports.route = (request, response) ->

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
                response.render 'posts', globalTimelineResponse.body
                timer.elapsedTime('Template render')

            else
                response.render 'posts', {error: 'Bad response from Twitter'}
