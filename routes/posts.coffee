################################################################################
#
# Tally App.net posts example.
#
# Displays the global timeline from App.net.
#
# Copyright © 2013, Aral Balkan.
# Released under the MIT license. (http://opensource.org/licenses/MIT)
#
################################################################################

superagent = require 'superagent'

exports.route = (request, response) ->

    superagent.get('https://alpha-api.app.net/stream/0/posts/stream/global')

        .end (globalTimelineResponse) ->

            if globalTimelineResponse.body

                # Attach a custom function to the data to count the number of posts
                globalTimelineResponse.body.numberOfPosts = ->
                    return this.data.length

                response.render 'posts', globalTimelineResponse.body
            else
                response.render 'posts', {error: 'Bad response from Twitter'}
