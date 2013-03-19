var vows    = require('vows');
	assert  = require('assert');

var cpuinfo = require('../lib/cpuinfo');
var cpuutil = cpuinfo.cpuutil;

// Test Suite
vows.describe('collector test').addBatch({
	'when measuring cpu info' : {
		topic: function () { cpuutil(this.callback) },
		'CPU Metrics are >= 0': function(x,y,z){
			assert(x >= 0,'x == '+x);
			assert(y >= 0,'y == '+y);
			assert(z >= 0,'z == '+z);
		},
		'CPU Metrics are <= 100': function(x,y,z){
			assert(x <= 100,'x == '+x);
			assert(y <= 100,'y == '+y);
			assert(z <= 100,'z == '+z);
		}
	}
}).export(module);
