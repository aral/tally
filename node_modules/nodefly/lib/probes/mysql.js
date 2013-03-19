/*
 * Copyright (c) 2012 Dmitri Melikyan
 *
 * Permission is hereby granted, free of charge, to any person obtaining a 
 * copy of this software and associated documentation files (the 
 * "Software"), to deal in the Software without restriction, including 
 * without limitation the rights to use, copy, modify, merge, publish, 
 * distribute, sublicense, and/or sell copies of the Software, and to permit 
 * persons to whom the Software is furnished to do so, subject to the 
 * following conditions:
 * 
 * The above copyright notice and this permission notice shall be included 
 * in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN 
 * NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR 
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


var nf = require('../nodefly');
var proxy = require('../proxy');
var samples = require('../samples');
var tiers = require('../tiers');
var topFunctions = require('../topFunctions');
var graphHelper = require('../graphHelper');

module.exports = function(obj) {

	proxy.after(obj, ['createClient', 'createConnection'], function(obj, args, ret) {
		var client = ret;

		proxy.before(client, 'query', function(obj, args) {
			if(nf.paused) return;

			var trace = samples.stackTrace();
			var command = args.length > 0 ? args[0] : undefined;

			var params = args.length > 1 && Array.isArray(args[1]) ? args[1] : undefined;
			var time = samples.time("MySQL", "query");

			var graphNode = graphHelper.startNode('MySQL', command, nf);

			proxy.callback(args, -1, function(obj, args, extra, graph, currentNode) {
				if(!time.done()) return;
				topFunctions.add('mysqlCalls', command, time.ms);

				graphHelper.updateTimes(graphNode, time);


				if (extra) {
					extra.mysql = extra.mysql || 0;
					extra.mysql += time.ms;
					if (extra.closed) {
						tiers.sample('mysql_out', time);
					}
					else {
						tiers.sample('mysql_in', time);
					}
				}
				else {
					tiers.sample('mysql_in', time);
				}
			}, null, true);

			if (graphNode) nf.currentNode = graphNode.prevNode;
		});
	});
};

