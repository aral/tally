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


var Time = require('./time').Time;


var nf;
var info;
var state = {};
var roots = [];
var operations = [];
var macroCallStack = {};
var stackTraceCalls = 0;
var operationFilter = /127\.0\.0\.1\:8002/;


exports.init = function() {
  nf = global.nodefly;


  nf.on('info', function(_info) {
    info = _info;
  });

  nf.on('call', function(point, time) {
    if(time.isMacro) macroCallStack[time.id] = time.begin;
  });

  nf.on('metric', function(metric) {
    if(!state[metric.scope]) state[metric.scope] = {};
    state[metric.scope][metric.name + (metric.unit ? ' (' + metric.unit + ')' : '')] = metric.value;
  });


  // cleanup operations
  setInterval(function() {
    try {
      // expire root calls
      var now = nf.millis();
      for(var prop in macroCallStack) {
        if(macroCallStack[prop] + 60000 < now) {
          delete macroCallStack[prop];
        }
      }

      var firstCall = undefined;
      for(var prop in macroCallStack) {
          firstCall = macroCallStack[prop];
          break;
      }

      operations = operations.filter(function(s) {
        return (firstCall && s._begin >= firstCall);
      });
    }
    catch(e) {
      nf.error(e);
    }
  }, 10000);

  // reset stack trace counter
  setInterval(function() {
    try {
      stackTraceCalls = 0;
    }
    catch(e) {
      nf.error(e);
    }
  }, 60000);
}

exports.time = function(scope, command, isMacro) {
  var t =  new Time(scope, command, isMacro);
  t.start();

  return t;
}; 


exports.truncate = function(args) {
  if(!args) return undefined;

  if(typeof args === 'string') {
    return (args.length > 80 ? (args.substr(0, 80) + '...') : args); 
  }
  
  if(!args.length) return undefined;

  var arr = [];
  var argsLen = (args.length > 10 ? 10 : args.length); 
  for(var i = 0; i < argsLen; i++) {
   if(typeof args[i] === 'string') {
      if(args[i].length > 80) {
        arr.push(args[i].substr(0, 80) + '...'); 
      }
      else {
        arr.push(args[i]); 
      }
    }
    else if(typeof args[i] === 'number') {
      arr.push(args[i]); 
    }
    else if(args[i] === undefined) {
      arr.push('[undefined]');
    }
    else if(args[i] === null) {
      arr.push('[null]');
    }
    else if(typeof args[i] === 'object') {
      arr.push('[object]');
    }
    if(typeof args[i] === 'function') {
      arr.push('[function]');
    }
  } 

  if(argsLen < args.length) arr.push('...');

  return arr;
};



exports.stackTrace = function() {
  if(this.stackTraceCalls++ > 1000) return undefined;

  var err = new Error();
  Error.captureStackTrace(err);

  if(err.stack) {
    var lines = err.stack.split("\n");
    lines.shift();
    lines = lines.filter(function(line) {
      return (!line.match(/nodefly/) || line.match(/nodefly\/test/));;
    });

    return lines; 
  }

  return undefined;
};


exports.add = function(time, sample, label) {

  process.nextTick(function() {
    sample._version = nf.version;
    sample._ns = 'samples';
    sample._id = time.id;
    sample._isMacro = time.isMacro;
    sample._begin = time.begin;
    sample._end = time.end;
    sample._ms = time.ms;
    sample._ts = time.begin;
    sample._cputime = time.cputime

    if(label && label.length > 80) label = label.substring(0, 80) + '...';
    sample._label = label;

    sample['Response time (ms)'] = sample._ms;
    sample['Timestamp (ms)'] = sample._ts;
    if(sample._cputime !== undefined) sample['CPU time (ms)'] = sample._cputime;



    if(sample._isMacro) {
      sample['Operations'] = findOperations(sample);
      sample['Application state'] = state;
      sample['Node information'] = info;

      try {
        if(!nf.filterFunc || nf.filterFunc(sample)) {
          nf.emit('sample', sample);
        }
      }
      catch(err) {
        nf.error(err);
      }

      delete macroCallStack[sample._id];
    }
    else if(!sample['URL'] || !operationFilter.exec(sample['URL'])) {
      operations.push(sample);

      try {
        if(!nf.filterFunc || nf.filterFunc(sample)) {
          nf.emit('sample', sample);
        }
      }
      catch(err) {
        nf.error(err);
      }
    }
  });
}


var findOperations = function(sample) {
  var found = [];

  operations.forEach(function(s) {
    if(s._begin >= sample._begin && s._end <= sample._end)
      found.push(s);
  });
        
  found = found.sort(function(a, b) {
    return b._ms - a._ms;
  });

  return found.splice(0, 50);
};



