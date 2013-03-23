require 'should'
tally = (require '../lib/tally-express').render

describe 'Tally', ->
	it 'should render the passed text', ->
		tally('<html><p data-tally-text="theText"></p></html>', {theText:'some text'}).should.equal('<html><p data-tally-text="theText">some text</p></html>')

	it 'should replace text with the passed text', ->
		tally('<html><p data-tally-text="theText">default text</p></html>', {theText:'some other text'}).should.equal('<html><p data-tally-text="theText">some other text</p></html>')

	it 'should render the passed attribute', ->
		tally('<html><a data-tally-attribute="href theURL"></a></html>', {theURL: 'http://aralbalkan.com'}).should.equal('<html><a data-tally-attribute="href theURL" href="http://aralbalkan.com"></a></html>')

	it 'should replace the attribute with the passed attribute', ->
		tally('<html><a data-tally-attribute="href theURL" href="http://moderniosdevelopment.com"></a></html>', {theURL: 'http://aralbalkan.com'}).should.equal('<html><a data-tally-attribute="href theURL" href="http://aralbalkan.com"></a></html>')

	it 'should render multiple attributes', ->
		tally('<html><a data-tally-attribute="href theURL; class theClass"></a></html>', {theURL: 'http://aralbalkan.com', theClass: 'classy'}).should.equal('<html><a data-tally-attribute="href theURL; class theClass" class="classy" href="http://aralbalkan.com"></a></html>')

	it 'should repeat nodes with data-tally-repeat', ->
		template = '<html><ul><li data-tally-repeat="person people"><span data-tally-text="person.name"></span></li></ul></html>'
		data = { people:[ {name: 'Aral'}, {name: 'Laura'}, {name: 'Natalie'}, {name: 'Osky'} ] }
		result = '<html><ul><li data-tally-repeat="person people" style=""><span data-tally-text="person.name">Aral</span></li><li style="" data-tally-alias="person people 1" data-tally-dummy="1"><span data-tally-text="person.name">Laura</span></li><li style="" data-tally-alias="person people 2" data-tally-dummy="1"><span data-tally-text="person.name">Natalie</span></li><li style="" data-tally-alias="person people 3" data-tally-dummy="1"><span data-tally-text="person.name">Osky</span></li></ul></html>'

		# console.log(tally(template, data))

		tally(template, data).should.equal(result)

	it 'should include elements with truthy conditionals', ->
		tally('<html><p data-tally-if="truthy"></p></html>', {truthy: yes}).should.equal('<html><p data-tally-if="truthy" style=""></p></html>')


