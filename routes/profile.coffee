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

        .end (error, globalTimelineResponse) ->

            timer.elapsedTime('Data transfer from App.net')

            # Attach a custom function to the data to count the number of posts
            globalTimelineResponse.body.numberOfPosts = ->
                return this.data.length

            globalTimeline = globalTimelineResponse.body

            # Handle network and App.net errors gracefully.
            if error
                # There was a network error
                globalTimeline.errorType = 'Network'
                globalTimeline.error = error

            else if not globalTimeline.data

                # FIX: This is a workaround for a limitation in Tally at the moment
                # where a node is not removed if a conditional fails.
                globalTimeline.data = []

                # There was an App.net error
                globalTimeline.errorType = 'App.net'
                globalTimeline.error = "(##{globalTimeline.meta.code}) #{globalTimeline.meta.error_message}"

            # Time the template render
            timer.reset()
            response.render 'posts', globalTimelineResponse.body
            timer.elapsedTime('Template render')
