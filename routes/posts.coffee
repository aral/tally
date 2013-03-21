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

        .end (error, globalTimelineResponse) ->

            # Attach a custom function to the data to count the number of posts
            globalTimelineResponse.body.numberOfPosts = ->
                if this.data
                    return this.data.length
                else
                    return 0

            globalTimeline = globalTimelineResponse.body

            # Option to render a static template.
            globalTimeline.__tally = { renderStatic: yes }

            # Handle network and App.net errors gracefully.
            if error
            	# There was a network error
            	globalTimeline.errorType = 'Network'
            	globalTimeline.error = error

            else if not globalTimeline.data

            	# There was an App.net error
            	globalTimeline.errorType = 'App.net'
            	globalTimeline.error = "(##{globalTimeline.meta.code}) #{globalTimeline.meta.error_message}"

            # Render the response
            response.render 'posts', globalTimeline
