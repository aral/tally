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

var crypto = require('crypto');
var util = require('util');
var nf = require('../nodefly');
var proxy = require('../proxy');
var samples = require('../samples');
var tiers = require('../tiers');
var _ = require('underscore');
var topFunctions = require('../topFunctions');
var graphHelper = require('../graphHelper');

var config = global.nodeflyConfig;

module.exports = function(http) {
	
	// server probe
	proxy.before(http.Server.prototype, [ 'on', 'addListener' ], function(obj,
			args) {
		
		// store ref to server so we can pull current connections
		nf.server_obj = obj;

		if (nf.server_obj.connCount === undefined)
			nf.server_obj.connCount = 0;

		if (args[0] !== 'request')
			return;

		proxy.callback(args, -1, function(obj, args) {
			nf.server_obj.connCount++;

			if (nf.paused)
				return;

			var req = args[0];
			var res = args[1];
			var time = samples.time("HTTP Server", req.url, true);
			req.tiers = time.tiers = nf.extra = {};

			var graph = nf.graph = { nodes: [ { name: req.url } ], links: [] };
			req.graph = graph;
			var currentNode = nf.currentNode = 0;

			proxy.before(req, [ 'on', 'addListener' ], function(req, args) {
				proxy.callback(args, -1, function(obj, args) {
					// noop
				});
			});

			proxy.after(res, 'end', function(obj, args) {
				if (!time.done())
					return;

				try {
					graph.nodes[0].value = time.ms;
					topFunctions.add('httpCalls', req.url, time.ms, time.cputime, time.tiers, graph);
					tiers.sample('http', time);
				} catch (e) {
					console.log("problems!!!\n", e.stack);
					process.exit(0);
				}

				time.tiers.closed = true;
			}); // res.end
		},
		function(obj,args){
			nf.graph = undefined;
			nf.currentNode = undefined;
			nf.extra = undefined;
		}); // callback
		
	}); //server 

	// client probe
	function getClientResponseHandler(url, host, time, graphNode) {
		return function handleResponseCb(obj, args, extra) {
			var res = args[0];
			
			proxy.before(res, [ 'on', 'addListener', 'once'], function(res, args) {
				if (args[0] !== 'end') return;
				
				proxy.callback(args, -1, function(obj, args, extra) {					
					if (!time || !time.done()) return;
					
					topFunctions.add('externalCalls', url, time.ms, time.cputime);
					graphHelper.updateTimes(graphNode, time);

					if (extra) {
						extra[host] = extra[host] || 0;
						extra[host] += time.ms;

						if (extra.closed) {
							if (typeof host === 'string')
								tiers.sample(host + '_out', time);
						}
						else {
							if (typeof host === 'string')
								tiers.sample(host + '_in', time);
						}

					}
				}); // res end cb
				
			}); // res end
		}
	}
	

	// handle http.request with callback
	proxy.before(http, 'request', function(obj, args) {
		var opts = args[0];
		var cb = args[1];
		
		if (typeof cb != 'function') return;

		if (opts.headers || opts._headers) {
			// get the url
			var headers = opts._headers || opts.headers;
			var method = opts.method || '';
			var host = headers.Host || headers.host || '';
			var path = opts.path;
			var url = util.format('%s http://%s%s', method, host, path);

			// don't track the agent calling home
			var nfServer = config.server;
			var re = new RegExp(host);
			if (nfServer.match(re)) return;

			var time = samples.time("HTTP Client", url, true);
			var graphNode = graphHelper.startNode('Outgoing HTTP', url, nf);

			proxy.callback(args, -1, getClientResponseHandler(url, host, time, graphNode));
			if (graphNode) nf.currentNode = graphNode.prevNode;
		}
	});



	// handle ClientRequest, evented.
	if (http.ClientRequest && http.ClientRequest.prototype) {

		proxy.before(http.ClientRequest.prototype, ['on', 'addListener', 'once'], function onResponse(req, args){
			if (args[0] !== 'response')
				return;
			

			if (req._headers || req.headers) {
				var headers = req._headers || req.headers;
				var method = req.method || '';
				var host = headers.Host || headers.host || '';
				var path = req.path;
				var url = util.format('%s http://%s%s', method, host, path);

				// don't track the agent calling home
				var nfServer = config.server;
				var re = new RegExp(host);
				if (nfServer.match(re)) return;

				var time = samples.time("HTTP Server", url, true);
				var graphNode = graphHelper.startNode('Outgoing HTTP', url, nf);
				
				proxy.callback(args, -1, getClientResponseHandler(url, host, time, graphNode));
				if (graphNode) nf.currentNode = graphNode.prevNode;
			}

		}); // before on/add/once

	} // http.ClientRequest

	
};