jsdom = require 'jsdom'
fs = require 'fs'
handlebars = require 'handlebars'

#
# The heavy-lifting is done with Distal.
# http://code.google.com/p/distal/
#
distal = (fs.readFileSync __dirname + '/distal-dev.js', 'utf8').toString()

exports.__express = (path, data, callback) ->
	fs.readFile path, 'utf8', (error, template) ->
		if error
			return callback(error)

		# Create the DOM.
		document = jsdom.jsdom(template, '2')
		window = document.createWindow()
		window.console = console

		# Flag so our modified Distal can know it is running
		# server side so that it knows to remove nodes that
		# don’t satisfy conditionals (data-qif) instead of
		# setting their display to none as makes sense on the client.
		data.aralbalkan = {tallyRunningInNode: yes}

		# console.log data

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

		if data.hybrid == yes
			console.log 'Hybrid'
			# Hybrid: now, let’s run it through handlebars
			handleBarsTemplate = handlebars.compile(html)
			html = handleBarsTemplate(data)

		# console.log(html)
		callback(null, html)
