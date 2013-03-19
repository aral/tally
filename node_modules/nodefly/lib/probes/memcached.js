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

var commands = [
	'get',
	'gets',
	'getMulti',
	'set',
	'replace',
	'add',
	'cas',
	'append',
	'prepend',
	'increment',
	'decrement',
	'incr',
	'decr',
	'del',
	'delete',
	'version',
	'flush',
	'samples',
	'slabs',
	'items',
	'flushAll',
	'samplesSettings',
	'samplesSlabs',
	'samplesItems',
	'cachedump'
];


module.exports = function(memcached) {

	commands.forEach(function(command) {
		proxy.before(memcached.prototype, command, function(client, args) {
			if(nf.paused) return;

			// ignore, getMulti will be called
			if(command === 'get' && Array.isArray(args[0])) return;

			var time = samples.time("Memcached", command);
			var graphNode = graphHelper.startNode('Memcached', command, nf);

			var query = command + ' ' + args[0];
			proxy.callback(args, -1, function(obj, args, extra) {
				if(!time.done()) return;

				topFunctions.add('memcacheCalls', query, time.ms);
				graphHelper.updateTimes(graphNode, time);
				if (extra) {
					extra.memcached = extra.memcached || 0;
					extra.memcached += time.ms;
					if (extra.closed) {
						tiers.sample('memcached_out', time);
					}
					else {
						tiers.sample('memcached_in', time);
					}
				}

			});

			if (graphNode) nf.currentNode = graphNode.prevNode;
		});
	});
};

