githubFlavouredMarkdown = require 'ghm'
fs = require 'fs'

exports.route = (request, response) ->
	fs.readFile __dirname + '/../readme.md', 'utf-8', (error, markdown) ->
		if error
			response.status(404)
			response.render 'readme'
		else
			readme = githubFlavouredMarkdown.parse(markdown)
			response.status(200).send(readme)