var debug;
if (process.env.NODEFLY_DEBUG && /event/.test(process.env.NODEFLY_DEBUG)) {
	debug = function(x) { console.error('EVENT_LOOP: %s', x); };
} else {
	debug = function() { };
}

var EventEmitter = require('events').EventEmitter;
var util = require('util');
var proxy = require('./proxy');

var stats = require('./node-measured').createCollection();

var nf;


// measures time to next tick
function checkNextTick(obj, args) {
	var t = Date.now();

	function beforeTick (obj, args, extra, context) {
		var now = Date.now();
		var dt = now - t;
		
		if (dt > nf.blockThreshold) {			
			stats.aggregator('wait').mark(dt);
			stats.meter('rate').mark();
		}

		if (context && context.graph) {
			context.graph.ticks++;
		}
	}
	
	proxy.callback(args, -1, beforeTick);	
}

function nodeflyNoOp() {}

function checkTimers(obj, args){
	// callback for any setTimeout or setInterval
	proxy.callback(args, -1, function(obj, args, extra, graph, currentNode) {
		process.nextTick(nodeflyNoOp);
	});
}

function checkEvents(obj, args, methName){
	 var eventName = args[0];
	 var emitterName = obj.constructor.name;
	 var cbName = args[args.length-1].name || 'anonymous';
	 var eventData = {
	 	eventName: eventName,
	 	emitterName: emitterName,
	 	methName: methName
	 };

	 var bindString = util.format('%s.%s(\'%s\', %s', emitterName, methName, eventName, cbName);

	 debug(bindString);

	// callback for any IO
	proxy.callback(args, -1, function(obj, args, extra, graph, currentNode) {
		process.nextTick(nodeflyNoOp);
	}, null, eventData);
}



function sample(code,time) {
	stats.aggregator(code).mark(time.ms);
}

var qStats;
var update;

function startEmitingQueueStats(){
	setInterval(function emitQueueStats(){
		stats._ts = nf.millis();
		qStats = stats.toJSON();
		
		if (!qStats || !qStats.rate || !qStats.wait) {
			update = [ 0, 0 ];
		}
		else {
			update = [qStats.rate.mean, qStats.wait.avg];
		}
		nf.metric(null, 'queue', update);
		//nf.emit('queue', update);
		
		stats.reset();
	}, 10*1000);
}


exports.init = function() {
	nf = global.nodefly;

	proxy.before(process, [ 'nextTick' ], checkNextTick);
	//proxy.before(EventEmitter.prototype, [ 'addListener', 'on', 'once' ], checkEvents);
	proxy.before(global, [ 'setTimeout', 'setInterval' ], checkTimers);
	
	startEmitingQueueStats();
};
