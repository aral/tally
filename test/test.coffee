require 'should'
tally = (require '../lib/tally-express').render

describe 'Tally', ->
	it 'should render the passed text', ->
		tally('<html><p data-tally-text="theText"></p></html>', {theText:'some text'}).should.equal('<html><p data-tally-text="theText">some text</p></html>')
