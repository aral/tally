var nf = require('../nodefly');
var proxy = require('../proxy');
var samples = require('../samples');
var tiers = require('../tiers');
var _ = require('underscore');
var topFunctions = require('../topFunctions');
var graphHelper = require('../graphHelper');


var internalCommands = [
	'_executeQueryCommand', 
	'_executeInsertCommand', 
	'_executeUpdateCommand', 
	'_executeRemoveCommand'
];

var commandMap = {
	'_executeQueryCommand': 'find', 
	'_executeInsertCommand': 'insert', 
	'_executeUpdateCommand': 'update', 
	'_executeRemoveCommand': 'remove'
};

var tier = 'mongodb';
function recordExtra(extra, time) {
	if (extra) {

		extra[tier] = extra[tier] || 0;
		extra[tier] += time.ms;

		if (extra.closed) {
			tiers.sample(tier + '_out', time);
		}
		else {
			tiers.sample(tier + '_in', time);
		}
	}
	else {
		tiers.sample(tier + '_in', time);
	}
}

module.exports = function(mongodb) {
	internalCommands.forEach(function(internalCommand) {
		proxy.before(mongodb.Db.prototype, internalCommand, function(obj, args) {
			var command = args[0] || {};
			var options = args[1] || {};

			var cmd = commandMap[internalCommand];
			var query = JSON.stringify(command.query);
			var spec = JSON.stringify(command.spec);
			var q = query || spec || '{}';
			var collectionName = command.collectionName;

			var fullQuery = collectionName + '.' + cmd + '(' + q;


			var time = samples.time("MongoDB", commandMap[internalCommand]);
			var hasCb = _.any(args, function(arg) { return (typeof arg === 'function'); });

			var graphNode = graphHelper.startNode('MongoDB', fullQuery, nf);

			if (!hasCb) {
				// updates and inserts are fire and forget unless safe is set
				// record these in top functions, just for tracking
				topFunctions.add('mongoCalls', fullQuery, 0);
				tiers.sample(tier + '_in', time);
			}
			else {
				proxy.callback(args, -1, function(obj, args, extra, graph, currentNode) {
					if(!time.done()) return;
					topFunctions.add('mongoCalls', fullQuery, time.ms);

					recordExtra(extra, time);

					graphHelper.updateTimes(graphNode, time);
				});
			}

			if (graphNode) nf.currentNode = graphNode.prevNode;
		});
	}); // all commands
}; // require mongo








