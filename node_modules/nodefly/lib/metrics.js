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


var os = require('os');
var config = global.nodeflyConfig;

var nf;
var metrics = {};


exports.init = function() {
  nf = global.nodefly;

  setInterval(function() {
    try {
      aggregate();
    }
    catch(e) {
      nf.error(e);
    }
  }, config.metricsInterval);

  //send any initial values
  setTimeout(function() {
    try {
      initial();
    }
    catch(e) {
      nf.error(e);
    }
  }, 1000);
};


exports.add = function(scope, name, value, unit, op, session) {

	if (!scope) scope = 'default-scope';
	
  process.nextTick(function() {
    var key = scope + ':' + name;
    if(!metrics[key]) {
      metrics[key] = {
        scope: scope,
        name: name,
        value: 0,
        _count: 0,
        unit: unit,
        op: op,
        session: session
      };

      if(op === 'hist')
        metrics[key].value = {};
    }

    var obj = metrics[key];
    if(!op || op === 'val') {
      obj.value = value;
    }
    else if(op === 'hist') {
      var bin = Math.pow(10, Math.floor(Math.log(value) / Math.LN10) + 1); 
      if(obj.value[bin]) {
        obj.value[bin]++;
      }
      else {
        obj.value[bin] = 1;
      }
    }
    else { // sum, avg
      obj.value += value;
      obj._count++;
    }
  });
};


var emit = function(obj) {
  try {
    delete obj._count;
    obj._id = nf.nextId++; 
    obj._ns = 'metrics';
    obj._ts = nf.millis();
 
    nf.emit('metric', obj);
  }
  catch(err) {
    nf.error(err);
  }
};

var initial = function() {
  for (var key in metrics) {
    var obj = metrics[key];

    if(!obj.op || obj.op === 'val') {
      emit(obj);

      delete metrics[key];
    }
  }  
};


var aggregate = function() {
  for (var key in metrics) {
    var obj = metrics[key];

    if(obj.op === 'avg') {
      obj.value = Math.round(obj.value / obj._count);
    }

    emit(obj);
  }

  metrics = {};
};

