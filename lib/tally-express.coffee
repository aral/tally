################################################################################
#
# Tally Express.
#
# Released under the MIT license.
#
# Copyright (c) 2013 Aral Balkan.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
################################################################################

jsdom = require 'jsdom'
fs = require 'fs'

# Load the Tally engine.
tally = (fs.readFileSync __dirname + '/tally.js', 'utf8').toString()

# The Express 3 export.
exports.__express = (path, data, callback) ->
	fs.readFile path, 'utf8', (error, template) ->
		if error
			return callback(error)

		html = render(template, data)

		callback null, html

render = (template, data) ->
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
	# Static output option: if set, tally will strip the following
	# from templates rendered on the server:
	#
	# 1. All Tally attributes
	# 2. Any elements with falsy values for data-tally-if
	#
	# (Note: any elements marked data-tally-dummy are stripped from
	#  ===== final output regardless of this setting. Also, this setting
	#        has no effect when Tally is used on the client side.)
	#
	if data.__tally['renderStatic']
		window.tally.renderStatic = yes

	#
	# Save the data on the DOM and run Tally.
	#
	window.data = data

	# NB. window.document is tracing out as [ null ] in the function itself
	# === although window.document.innerHTML works. window.document.documentElement
	#     also works. I’ll be darned if I know why or where the problem is.
	try
		window.run ('tally(window.document.documentElement, window.data);')
	catch e
		throw e

	html = window.document.innerHTML;

	return html

exports.render = render
