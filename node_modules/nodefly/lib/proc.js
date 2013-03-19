/*!
 * proc
 * Copyright(c) 2012 Daniel D. Shaw <dshaw@dshaw.com>
 * MIT Licensed
 */

/**
 * Module dependencies.
 */

var fs = require('fs');

/**
 * Exports.
 */

function readTimespec(buf, offset) {
  return buf.readInt32LE(offset) + (buf.readInt32LE(offset + 4) / 1000000000);
}

exports.usageSync = function usageSync (pid) {

  var buf = fs.readFileSync('/proc/'+pid+'/usage');

  var data = {};
  data.lwpid = buf.readUInt32LE(0);                    // lwp id.  0: process or defunct
  data.count = buf.readUInt32LE(4);                    // number of contributing lwps
  data.tstamp = readTimespec(buf, 8);                  // current time stamp
  data.create = readTimespec(buf, 16) / data.count;    // process/lwp creation time stamp
  data.term = readTimespec(buf, 24) / data.count;      // process/lwp termination time stamp
  data.rtime = readTimespec(buf, 32) / data.count;     // total lwp real (elapsed) time
  data.utime = readTimespec(buf, 40);                  // user level cpu time
  data.stime = readTimespec(buf, 48);                  // system call cpu time
  data.ttime = readTimespec(buf, 56);                  // other system trap cpu time
  data.tftime = readTimespec(buf, 64);                 // text page fault sleep time
  data.dftime = readTimespec(buf, 72);                 // data page fault sleep time
  data.kftime = readTimespec(buf, 80);                 // kernel page fault sleep time
  data.ltime = readTimespec(buf, 88);                  // user lock wait sleep time
  data.slptime = readTimespec(buf, 96);                // all other sleep time
  data.wtime = readTimespec(buf, 104);                 // wait-cpu (latency) time
  data.stoptime = readTimespec(buf, 112);              // stopped time
                                                       // filler for future expansion
  data.minf = buf.readUInt32LE(168);                   // minor page faults
  data.majf = buf.readUInt32LE(172);                   // major page faults
  data.nswap = buf.readUInt32LE(176);                  // swaps
  data.inblk = buf.readUInt32LE(180);                  // input blocks
  data.outblk = buf.readUInt32LE(184);                 // output blocks
  data.msnd = buf.readUInt32LE(188);                   // messages sent
  data.mrcv = buf.readUInt32LE(192);                   // messages received
  data.sigs = buf.readUInt32LE(196);                   // signals received
  data.vctx = buf.readUInt32LE(200);                   // voluntary context switches
  data.ictx = buf.readUInt32LE(204);                   // involuntary context switches
  data.sysc = buf.readUInt32LE(208);                   // system calls
  data.ioch = buf.readUInt32LE(212);                   // chars read and written
                                                       // filler for future expansion
  return data;
};