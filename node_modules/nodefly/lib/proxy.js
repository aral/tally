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

var debug;
if (process.env.NODEFLY_DEBUG && /proxy/.test(process.env.NODEFLY_DEBUG)) {
	debug = function(x) { console.error('     PROXY: %s', x); };
} else {
	debug = function() { };
}

EventEmitter = require('events').EventEmitter;

var nodefly;

exports.init = function() {
	nodefly = global.nodefly;
}

var Locals = function() {
	this.time = undefined;
	this.stackTrace = undefined;
	this.params = undefined;
}


exports.before = function(obj, meths, hook) {
	if(!Array.isArray(meths)) meths = [meths];

	meths.forEach(function(meth) { 
		var orig = obj[meth];
		if(!orig) return;

		obj[meth] = function() {
			try { hook(this, arguments, meth); } catch(e) { nodefly.error(e); }
			return orig.apply(this, arguments);
		};
	});
};


exports.after = function(obj, meths, hook) {
	if(!Array.isArray(meths)) meths = [meths];

	meths.forEach(function(meth) {
		var orig = obj[meth];
		if(!orig) return;

		obj[meth] = function() {
			var ret = orig.apply(this, arguments);
			try { hook(this, arguments, ret); } catch(e) { nodefly.error(e) }
			return ret;
		};
	});
};


exports.around = function(obj, meths, hookBefore, hookAfter) {
	if(!Array.isArray(meths)) meths = [meths];

	meths.forEach(function(meth) {
		var orig = obj[meth];
		if(!orig) return;

		obj[meth] = function() {
			var locals = new Locals();
			try { hookBefore(this, arguments, locals); } catch(e) { nodefly.error(e) }
			var ret = orig.apply(this, arguments);
			try { hookAfter(this, arguments, ret, locals); } catch(e) { nodefly.error(e) }
			return ret;
		};
	});
};


exports.callback = function(args, pos, hookBefore, hookAfter, evData) {
	if(args.length <= pos) return false;
	if (pos === -1) {
		// search backwards for last function
		for (pos = args.length - 1; pos >= 0; pos--) {
			if (typeof args[pos] === 'function') {
				break;
			}
		}
	}


	// create closures on context vars
	var extra = nodefly.extra;
	var graph = nodefly.graph;
	var currentNode = nodefly.currentNode;

	var orig = (typeof args[pos] === 'function') ? args[pos] : undefined;
	if(!orig) return;

	var functionName = orig.name || 'anonymous';

	args[pos] = function() {		
		if (extra) nodefly.extra = extra;
		if (graph) nodefly.graph = graph;
		if (currentNode != undefined) nodefly.currentNode = currentNode;

		if(hookBefore) try { hookBefore(this, arguments, extra, graph, currentNode); } catch(e) { nodefly.error(e); }

		if (evData) debug(evData.emitterName + ' \'' + evData.eventName + '\' event -> ' + functionName + '()');
		var ret = orig.apply(this, arguments);
		if(hookAfter) try { hookAfter(this, arguments, extra, graph, currentNode); } catch(e) { nodefly.error(e); }

		if (extra) nodefly.extra = undefined;
		if (graph) nodefly.graph = undefined;
		if (currentNode != undefined) nodefly.currentNode = undefined;
		return ret;
	};

	orig.__proxy__ = args[pos];

	args[pos].__name__ = 'BEFORE_' + functionName;
};


exports.getter = function(obj, props, hook) {
	if(!Array.isArray(props)) props = [props];

	props.forEach(function(prop) {
		var orig = obj.__lookupGetter__(prop);
		if(!orig) return;

		obj.__defineGetter__(prop, function() {
			var ret = orig.apply(this, arguments);
			try { hook(this, ret); } catch(e) { nodefly.error(e) }
			return ret;
		});
	});
};



if(!EventEmitter.prototype.__patched__) {
	/* make sure a wrapped listener can be removed */
	exports.before(EventEmitter.prototype, 'removeListener', function(obj, args) {
		if(args.length > 1 && args[1] && args[1].__proxy__) {
			var functionName = args[1].name || 'anonymous';
			if (functionName === 'onServerResponseClose') {
				var closeEvents = '';
				if (obj._events.close instanceof Array) {
					obj._events.close.forEach(function(cb) {
						closeEvents += cb.__name__ + ',';
					});
				}
				debug('     close events: ' + closeEvents);
				debug('     removeListener(\'' + args[0] + '\',' + args[1].name);
			}
			args[1] = args[1].__proxy__;
		}
	});

	exports.after(EventEmitter.prototype, 'removeListener', function(obj, args) {
		if(args.length > 1 && args[1] && args[1].__proxy__) {
			var functionName = args[1].name || 'anonymous';
			if (functionName === 'onServerResponseClose') {
				var closeEvents = '';
				if (obj._events.close instanceof Array) {
					obj._events.close.forEach(function(cb) {
						closeEvents += cb.__name__ + ',';
					});
				}
				debug('     close events: ' + closeEvents);
			}
			args[1] = args[1].__proxy__;
		}
	});

	EventEmitter.prototype.__patched__ = true;
}


