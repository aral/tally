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

		#
		# Copy over formatters and hooks (if any) from the special __tally namespace
		# in the data object to the Tally object in the DOM.
		#

		#
		# Copy custom formatter(s), if any.
		# (Use custom formatters to modify values before they are rendered.)
		#
		customFormatters = data.__tally['formatters']
		if customFormatters
			window.tally.format[customFormatter] = customFormatters[customFormatter] for customFormatter of customFormatters

		#
		# Copy the attributeWillChange and textWillChange hooks.
		# (Use these hooks to perform actions before a node is modified—e.g., animate, run debug code.)
		#
		window.tally.attributeWillChange = data.__tally['attributeWillChange']
		window.tally.textWillChange = data.__tally['textWillChange']

		#
		# Inject Data option: if set, this will result in a copy
		# of the data being injected into the template at tally.data
		# (Useful if you want to append to it via Ajax calls, etc.
		# When rendering a timeline, for example.)
		#
		if data.__tally['injectData']
			head = window.document.getElementsByTagName('head')[0]
			script = window.document.createElement('script')
			script.setAttribute('type', 'text/javascript')
			script.textContent = 'tally.data = ' + JSON.stringify(data, null, 2) + ';'
			head.appendChild(script)

		#
		# Save the data on the DOM and run Tally.
		#
		window.data = data

		# NB. window.document is tracing out as [ null ] in the function itself
		# === although window.document.innerHTML works. window.document.documentElement
		#     also works. I’ll be darned if I know why or where the problem is.
		window.run ('tally(window.document.documentElement, window.data);')

		html = window.document.innerHTML;

		callback(null, html)
