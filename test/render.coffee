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
		tally(template, data).should.equal(result)

	it 'should display elements with truthy conditionals', ->
		tally('<html><p data-tally-if="truthy"></p></html>', {truthy: yes}).should.equal('<html><p data-tally-if="truthy" style=""></p></html>')

	it 'should hide elements with falsey conditionals', ->
		tally('<html><p data-tally-if="truthy"></p></html>', {truthy: no}).should.equal('<html><p data-tally-if="truthy" style="display: none;"></p></html>')

	it 'should handle "not:" conditionals correctly', ->
		tally('<html><p data-tally-if="not:dog">Want dog</p></html>', {dog: no}).should.equal('<html><p data-tally-if="not:dog" style="">Want dog</p></html>')

	it 'should handle "is" conditionals correctly', ->
		tally('<html><p data-tally-if="dog is Osky"></p></html>', {dog: 'Osky'}).should.equal('<html><p data-tally-if="dog is Osky" style=""></p></html>')

	it 'should handle "isNot" conditionals correctly', ->
		tally('<html><p data-tally-if="dog isNot Osky"></p></html>', {dog: 'Osky'}).should.equal('<html><p data-tally-if="dog isNot Osky" style="display: none;"></p></html>')

	it 'should handle "isGreaterThan" conditionals correctly', ->
		tally('<html><p data-tally-if="age isGreaterThan 18">You can drive.</p></html>', {age: 21}).should.equal('<html><p data-tally-if="age isGreaterThan 18" style="">You can drive.</p></html>')

	it 'should handle "isLessThan" conditionals correctly', ->
			tally('<html><p data-tally-if="age isLessThan 18">You can’t drive.</p></html>', {age: 21}).should.equal('<html><p data-tally-if="age isLessThan 18" style="display: none;">You can’t drive.</p></html>')

	it 'should handle "contains" conditionals correctly', ->
			tally('<html><p data-tally-if="statement contains sarcasm">I was being sarcastic</p></html>', {statement: 'This statement contains sarcasm. Literally.'}).should.equal('<html><p data-tally-if="statement contains sarcasm" style="">I was being sarcastic</p></html>')

	it 'should handle "doesNotContain" conditionals correctly', ->
			tally('<html><p data-tally-if="statement doesNotContain sarcasm">I’m serious</p></html>', {statement: 'This statement contains sarcasm. Literally.'}).should.equal('<html><p data-tally-if="statement doesNotContain sarcasm" style="display: none;">I’m serious</p></html>')

	# Note: should.js requires you to run the code that could throw an exception in an anonymous function and
	# ===== apply .should.throw() to that. My instinct was to actually run the function itself and apply it to that.
	it 'should fail conditionals with unknown operators', ->
		(->
			tally('<html><p data-tally-if="operand isLessThanny 2"></p></html>', {operand: 1})).should.throw('[ P ]')



	# it 'should not include data-tally-* attributes if renderStatic option is set', ->

	it 'should not include data-tally-dummy elements', ->
		tally('<html><p data-tally-dummy></p></html>', {}).should.equal('<html></html>')


