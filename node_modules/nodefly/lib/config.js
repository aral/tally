
var env = process.env.NODEFLY_ENV || 'prod';

var cfg = {
	prod: {
		collectInterval: 60 *1000,
		metricsInterval: 60 *1000,
		server: process.env.NODEFLY_AGENT_COLLECTOR || 'http://collector.nodefly.com:443',
		queueBlock: 10
	},
	dev: {
		collectInterval: 15 *1000,
		metricsInterval: 15 *1000,
		server: process.env.NODEFLY_AGENT_COLLECTOR || 'http://127.0.0.1:4001',
		queueBlock: 10
	}
}

module.exports = cfg[env];