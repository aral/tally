#
# Timer (modified from http://stackoverflow.com/questions/10617070/how-to-measure-execution-time-of-javascript-code-with-callbacks)
#
timers = {}
start = process.hrtime()

reset = ->
    start = process.hrtime()

elapsedTime = (note) ->
    precision = 3 # 3 decimal places
    elapsed = process.hrtime(start)[1] / 1000000; # ms from nanoseconds

    if not (timers[note] and Array.isArray timers[note])
        timers[note] = []

    times = timers[note]
    times.push elapsed

    sum = times.reduce (previousValue, currentValue) ->
        return previousValue + currentValue;
    sum = sum.toFixed(precision)
    numTries = times.length
    average = (sum / numTries).toFixed(precision)
    min = (Math.min.apply(Math, times)).toFixed(precision)
    max = (Math.max.apply(Math, times)).toFixed(precision)

    console.log("\n#{note}:\n
    Elapsed: #{elapsed} ms.\n
    Average: #{average} ms over #{numTries} tries (min: #{min} ms, max: #{max} ms).")

    start = process.hrtime() # reset the timer

exports.reset = reset
exports.elapsedTime = elapsedTime
