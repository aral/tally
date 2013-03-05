jsdom = require 'jsdom'
fs = require 'fs'
handlebars = require 'handlebars'

tally = (fs.readFileSync __dirname + '/tally.js', 'utf8').toString()

exports.__express = (path, data, callback) ->
	fs.readFile path, 'utf8', (error, template) ->
		if error
			return callback(error)

		# Create the DOM.
		document = jsdom.jsdom(template, '2')
		window = document.createWindow()
		window.console = console

		# Flag so Tally knows it is running under Tally-Express
		# server side so that it knows to remove nodes that
		# don’t satisfy conditionals (data-qif) instead of
		# setting their display to none as makes sense on the client.
		data.aralbalkan = {tallyRunningInNode: yes}

		# console.log data

		window.data = data
		window.run tally

		# Custom formatter
		window.tally.format['fullURL'] = (value) ->
			return 'http://' + value + '.com'

		# NB. window.document is tracing out as [ null ] in the function itself
		# === although window.document.innerHTML works. window.document.documentElement
		#     also works. I’ll be darned if I know why or where the problem is.
		window.run ('tally(window.document.documentElement, window.data);')

		html = window.document.innerHTML;

		if data.hybrid == yes
			console.log 'Hybrid'
			# Hybrid: now, let’s run it through handlebars
			handleBarsTemplate = handlebars.compile(html)
			html = handleBarsTemplate(data)

		# console.log(html)
		callback(null, html)
