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

var nf = require('./nodefly');

function Time(scope, command, isMacro) {
  var nf = global.nodefly;

  this.scope = scope;
  this.command = command;
  this.isMacro = isMacro;

  this.id = nf.nextId++; 

  this._begin = undefined;
  this._cputime = undefined;

  this.begin = undefined;
  this.end = undefined;
  this.ms = undefined;
  this.cputime = undefined;
};
exports.Time = Time;


Time.prototype.start = function() {
  var nf = global.nodefly;

  this.begin = nf.millis();
  this._cputime = nf.cputime();
  this._begin = nf.hrtime();

  var self = this;
  process.nextTick(function() {
    try {
      nf.emit("call", "start", self);
    }
    catch(err) {
      nf.error(err);
    }
  });
};


Time.prototype.done = function() {
  var nf = global.nodefly;

  if(this.end) return false;

  this.ms = (nf.hrtime() - this._begin) / 1000;
  if(this._cputime !== undefined) this.cputime = (nf.cputime() - this._cputime) / 1000;
  this.end = nf.millis();

  var self = this;
  process.nextTick(function() {
    nf.emit("call", "done", self);
  });

  return true;
};


