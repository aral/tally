githubFlavouredMarkdown = require 'ghm'
fs = require 'fs'

exports.route = (request, response) ->
	fs.readFile __dirname + '/../readme.md', 'utf-8', (error, markdown) ->
		data = {}

		if error
			response.status 404
			data.title = 'Could not find the readme.md file.'
			data.error = yes
		else
			readme = githubFlavouredMarkdown.parse(markdown)
			data.title = 'Read me!'
			data.readme = readme

		response.render 'readme', data