// Copyright (c) 2010 margus.rebane@gmail.com
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

jQuery.extend({
	fjFunctionQueue: function(funcToQue) {
		if (funcToQue == null) {
			if (jQuery.fjFunctionQueue.queue != null && jQuery.fjFunctionQueue.queue.queue.length > 0) {
				if (jQuery.fjFunctionQueue.queue.running) {
					jQuery.fjTimer({
						interval: jQuery.fjFunctionQueue.queue.properties.interval,
						tick: function(counter, timer) {
							var func = jQuery.fjFunctionQueue.queue.queue.shift();
							try {
								jQuery.fjFunctionQueue.queue.properties.onTick(jQuery.fjFunctionQueue.queue.index, func);
								jQuery.fjFunctionQueue.queue.index++;
							} catch (e) {
								jQuery.fjFunctionQueue();
								throw e;
							}
							if (jQuery.fjFunctionQueue.queue.queue.length > 0) {
								jQuery.fjFunctionQueue();
							} else {
								jQuery.fjFunctionQueue.queue.running = false;
								jQuery.fjFunctionQueue.queue.index = 0;
								jQuery.fjFunctionQueue.queue.properties.onComplete();
							}
						}
					});
				} else {
					jQuery.fjFunctionQueue.queue.running = true;
					jQuery.fjFunctionQueue();
				}
			}
		} else {
			if (jQuery.fjFunctionQueue.queue == null) {
				jQuery.fjFunctionQueue.queue = {index: 0, running: false, queue:[], properties: {interval: 1, onComplete: function(){}, onStart: function(){}, autoStart: true, onTick: function(counter, func) {func();}}};
			}
			var isEmptyArray = jQuery.fjFunctionQueue.queue.queue.length == 0;
			if (jQuery.isFunction(funcToQue)) {
				jQuery.fjFunctionQueue.queue.queue.push(funcToQue);
			} else if (jQuery.isArray(funcToQue)) {
				for(var i = 0; i < funcToQue.length; i++) {
					jQuery.fjFunctionQueue.queue.queue.push(funcToQue[i]);
				}
			} else {
				jQuery.fjFunctionQueue.queue.properties = jQuery.extend(jQuery.fjFunctionQueue.queue.properties, funcToQue);
			}
			if (isEmptyArray && jQuery.fjFunctionQueue.queue.queue.length > 0 && !jQuery.fjFunctionQueue.queue.running && jQuery.fjFunctionQueue.queue.properties.autoStart) {
				jQuery.fjFunctionQueue.queue.running = true;
				jQuery.fjFunctionQueue.queue.properties.onStart();
				jQuery.fjFunctionQueue.queue.running = false;
				jQuery.fjFunctionQueue();
			}
		}
	},
	fjTimer : function(properties) {
	    properties = jQuery.extend({interval: 10, tick: function(){}, repeat: false, random :false, onComplete: function(){}, step: 1}, properties);
	    var counter = 0;
	    var timer = new function() {
	    	this.timerId = null;
	    	this.stop = function() {
	    		clearInterval(this.timerId);
	    	}
	    }
	    timer.timerId = setInterval(function() {
	    	try {
	    		properties.tick(counter, timer);
	    		counter+=properties.step;
	    	} catch (e) {
	    		alert(e);
	    	}
	    	if (properties.repeat !== true && ((properties.repeat * properties.step) <= counter || properties.repeat === false)) {
	    		timer.stop();
	    		properties.onComplete();
	    	}
	    }, properties.interval);
	},
	fjTimerEach: function(properties) {
		var ___array = properties.array;
		var ___callback = properties.tick;
		properties.repeat = ___array.length;
		if (properties.step != null) {
			properties.repeat = Math.ceil(___array.length / parseInt(properties.step, 10));
		}
		properties.tick = function(counter, timer) {
			___callback(counter, ___array[counter]);
		}
		jQuery.fjTimer(properties);
	}
});