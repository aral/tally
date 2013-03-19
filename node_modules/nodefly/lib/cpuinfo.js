var fs = require('fs');
var proc = require('./proc');
var platform = require('os').platform();
var _ = require('underscore');

var last_stats_all;
var last_ptime;
var last_utime;
var last_stime;

var last_uptime;
var last_active = 0;


exports.cpuutil = function (onMetric)
{
	var pid = process.pid;
	var utime, stime, ptime, stats_all;
	
	if (platform === 'linux') {
		// TODO: move this into the proc module and check platform there
		fs.readFile('/proc/'+pid+'/stat', 'ascii',function(err,data){
			if(err) return;
			
			var stats_pid = data.split(' ');
			
			utime = parseInt(stats_pid[13]);
			stime = parseInt(stats_pid[14]);
			
			fs.readFile('/proc/stat', 'ascii', function(err,data){
				if(err) return;
				
				stats_all = data.match('cpu +(.*)\n')[1].split(' ');
				stats_all = array_sum(stats_all);
		
				if(last_stats_all){
					ptime = utime + stime;
					var ticks_delta  = (stats_all - last_stats_all);
					var percent_proc = (ptime - last_ptime)/ticks_delta*100;
					var percent_user = (utime - last_utime)/ticks_delta*100;
					var percent_syst = (stime - last_stime)/ticks_delta*100;
					onMetric (
						percent_proc,
						percent_user,
						percent_syst
					);
				}
		
				last_stats_all = stats_all;
				last_ptime = ptime;
				last_utime = utime;
				last_stime = stime;
			})
		});
		
	}
	else if (platform === 'sunos' || platform === 'solaris') {
		var usage = proc.usageSync(pid);
	    utime     = usage.utime;
	    stime     = usage.stime;
	    ptime     = utime + stime;
	    stats_all = usage.rtime;
		
		if (last_stats_all) {
			var ticks_delta  = (stats_all - last_stats_all);
			var percent_proc = (ptime - last_ptime)/ticks_delta*100;
			var percent_user = (utime - last_utime)/ticks_delta*100;
			var percent_syst = (stime - last_stime)/ticks_delta*100;

			onMetric (
				percent_proc,
				percent_user,
				percent_syst
			);
		}
		
		last_stats_all = stats_all;
		last_ptime = ptime;
		last_utime = utime;
		last_stime = stime;
		
	}
	else if (platform === 'darwin') {
		var ps = require('child_process').spawn('/bin/ps', ['-p', pid, '-o','utime,time,etime']);
		var res = '';
		ps.stdout.on('data',function(data){
			res += data;
		});
		ps.on('close',function(){
			var m = res.match(/ELAPSED\s*(\d*):(\d*\.\d*)\s*(\d*):(\d*\.\d*)\s*(?:(\d*)-)?(?:(\d*):)?(\d*):(\d*)/);
			
			if (m) {
				m.shift(); // toss the full match
    			
				var keys = [ 'uMinutes', 'uSeconds', 'pMinutes', 'pSeconds', 'rDays', 'rHours', 'rMinutes', 'rSeconds' ];
				
				var data = _.reduce(m, function(memo, val) { memo[keys.shift()] = parseFloat(val) || 0; return memo; }, {});
				
				utime = data.uMinutes * 60 + data.uSeconds;
				ptime = data.pMinutes * 60 + data.pSeconds;
				stime = ptime - utime;
				
				stats_all = ((data.rDays * 24 + data.rHours) * 60 + data.rMinutes) * 60 + data.rSeconds;
				
				if (last_stats_all) {
					var ticks_delta  = (stats_all - last_stats_all);
					var percent_proc = (ptime - last_ptime)/ticks_delta*100;
					var percent_user = (utime - last_utime)/ticks_delta*100;
					var percent_syst = (stime - last_stime)/ticks_delta*100;

					onMetric (
						percent_proc,
						percent_user,
						percent_syst
					);
				}
				
				last_stats_all = stats_all;
				last_ptime = ptime;
				last_utime = utime;
				last_stime = stime;

			}
			
		});
		
	}
	else if (platform === 'win32') {
		
		if(last_uptime){
			
			var ps = require('child_process').exec('tasklist /v',function(err,stdout,stderr){
				if(err){
					
				}else{
					stdout.split('\n').forEach(function(item){
						var items = item.split(/\s+/);
						var pid = parseInt(items[1]);
						if(pid === process.pid){
							var times = items[8].split(/[:.]/);
							
							var hour = parseInt(times[0]);
							var mins = parseInt(times[1]);
							var secs = parseInt(times[2]);
							
							// Total CPU Time of Process in Seconds
							var active = hour * 3600 + mins * 60 + secs;
							
							// Total Uptime of Process in Seconds
							var uptime = process.uptime();
							
							var uptime_delta = uptime - last_uptime;
							var active_delta = active - last_active;
							
							last_active = active;
							last_uptime = uptime;
							
							var usage = active_delta / uptime_delta;
							
							if(uptime_delta>0){
								if(usage>1){
									// Spike Alert
								}
								onMetric(usage*100,usage*100,0);
							}
							
						}
					})
				}
			});
			
		}else{
			last_uptime = process.uptime();
		}
		
	}
	
}

function array_sum(a){
	var k,s=0;
	if(typeof a!=='object')
		return null;
	for(k in a){
		s+=(a[k]*1);
	}
	return s;
}
