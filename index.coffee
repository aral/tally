express = require 'express'
fs = require 'fs'
# html5 = require 'html5'
# distal = require './lib/distal-dev.js'
# tally = require 'lib/tally'
handlebars = require 'handlebars'

jsdom = require 'jsdom'

distal = (fs.readFileSync __dirname + '/lib/distal.js', 'utf8').toString()

# Sample data
data =
    title: 'Express 3‐Tally sample'
    name: 'Express 3‐Tally'
    content: 'This is a simple example to demonstrate Express 3‐Tally'
    newURL: 'http://aralbalkan.com'
    correctURLFragment: 'moderniosdevelopment'
    aralImageURL: 'http://aralbalkan.com/images/aral.jpg'
    friends:
        [
            {name: 'Laura', skills: 'design, development, illustration, speaking'},
            {name: 'Seb', skills: 'particles, games, JavaScript, C++'},
            {name: 'Natalie', skills: 'HTML, CSS'}
        ]
    hybrid: no

# Set up Express with Tally as the templating engine.
app = express()

app.set 'views', __dirname + '/views'

app.engine 'html', (path, options, callback) ->
	fs.readFile path, 'utf8', (error, template) ->
		if error
			return callback(error)
		document = jsdom.jsdom(template, '2')

		window = document.createWindow()

		window.console = console
		window.data = data
		window.run distal

		# Custom formatter
		window.distal.format['fullURL'] = (value) ->
			return 'http://' + value + '.com'

		# NB. window.document is tracing out as [ null ] in the function itself
		# === although window.document.innerHTML works. window.document.documentElement
		#     also works. I’ll be darned if I know why or where the problem is.
		window.run ('distal(window.document.documentElement, window.data);')

		html = window.document.innerHTML;

		if data.hybrid
			console.log 'Hybrid'
			# Hybrid: now, let’s run it through handlebars
			handleBarsTemplate = handlebars.compile(html)
			html = handleBarsTemplate(data)

		# console.log(html)
		callback(null, html)


app.get '/', (request, response) ->
	data.hybrid = no
	response.render 'index.html', data


app.get '/hybrid', (request, response) ->
	data.hybrid = yes
	response.render 'hybrid.html', data


app.listen 3000

console.log 'Express-Tally is listening on port 3000…'

