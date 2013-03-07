################################################################################
#
# Tally simple example.
#
# Demonstrates how to map static data to a template.
#
# Copyright © 2013, Aral Balkan.
# Released under the MIT license. (http://opensource.org/licenses/MIT)
#
################################################################################

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

exports.route = (request, response) ->

    # Custom formatter
    data.__tally = {
        formatters:
            fullURL: (value) ->
                return 'http://' + value + '.com'
    }

    response.render 'simple', data

