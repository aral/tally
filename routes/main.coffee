fs = require 'fs'

exports.route = (request, response) ->

	# Get the version to display in the index page.
	fs.readFile __dirname + '/../package.json', 'utf-8', (error, data) ->
		if error
			throw new Error(error)
		packageJSON = JSON.parse(data)
		version = packageJSON['version']

		response.render 'main', {version: version}