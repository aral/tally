jsdom = require 'jsdom'
fs = require 'fs'

# Load the Tally engine.
tally = (fs.readFileSync __dirname + '/tally.js', 'utf8').toString()

# The Express 3 export.
exports.__express = (path, data, callback) ->
	fs.readFile path, 'utf8', (error, template) ->
		if error
			return callback(error)

		# Create the DOM.
		document = jsdom.jsdom(template, '2')
		window = document.createWindow()
		window.console = console

		# Create a private member in the data to communicate with the Tally engine in the DOM.
		data.__tally = {} unless data.__tally

		# Flag so Tally knows it is running on the server
		# and will remove nodes that don’t satisfy conditionals
		# (data-qif) instead of setting them to display: none
		# like it does when running on the client.
		data.__tally['server'] = yes;

		# Create Tally in the DOM.
		window.run tally

		# If the user has added custom formatters to the data object,
		# copy them over to Tally.
		customFormatters = data.__tally['formatters']
		if customFormatters
			window.tally.format[customFormatter] = customFormatters[customFormatter] for customFormatter of customFormatters

		# Save the data on the DOM and run Tally.
		window.data = data

		# NB. window.document is tracing out as [ null ] in the function itself
		# === although window.document.innerHTML works. window.document.documentElement
		#     also works. I’ll be darned if I know why or where the problem is.
		window.run ('tally(window.document.documentElement, window.data);')

		html = window.document.innerHTML;

		callback(null, html)
