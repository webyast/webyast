/*!
 * jQuery Activity
 * December 20, 2009
 * Corey Hart @ http://www.codenothing.com

The MIT License

Copyright (c) 2009 Corey Hart

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

 */

(function($, undefined){
	// Current Timestamp
 	function now(){
		return (new Date).getTime();
	}

	// Attach activity object to jQuery base object
	$.activity = {
		// Variable Storage
		defaults: {
			// Users last active timestamp
			lastActive: now(),

			// Interval times in milliseconds
			inactive: 1000*60*30, // Default inactive at 30 minutes
			interval: 1000*60*5, // Default interval check every 5 minutes

			// Callback functions when intervals are reached
			inactiveFn: function(){},
			intervalFn: function(){}
		},

		// Timerid
		timer: undefined,

		// Expose the current time fn
		now: now,

		// Starts the interval
		init: function(options){
			// Update vars with options
			var self = this;
			self.defaults = $.extend(self.defaults, options||{});
			self.defaults.lastActive = now();

			// Check activity on a continuous interval
			self.bind();
			return self.timer = setInterval(function(){ self.check(); }, self.defaults.interval);
		},

		// Updates lastActive to current/provided timestamp
		update: function(time){
			return (this.defaults.lastActive = time === undefined ? now() : time);
		},

		// Returns boolean indicator of activity
		isActive: function(){
			return (this.timer !== undefined);
		},

		// Getter for current activity
		getActivity: function(){
			var self = this, time = now();
			return {diff: time-self.defaults.lastActive, time: time, lastActive: self.defaults.lastActive};
		},

		// Re-activates the interval (options only required if change to defaults wanted)
		reActivate: function(options){
			var self = this;
			// Clear interval if still running
			if (self.timer)
				self.timer = clearInterval(self.timer);
			// Reactivation
			return self.init(options||{});
		},

		// Interval check function
		check: function(){
			var self = this,
				time = now(),
				diff = time - self.defaults.lastActive;

			// Trigger appropriate callback
			if (diff > self.defaults.inactive){
				self.defaults.inactiveFn.call(self, {diff: diff, time: time, lastActive: self.defaults.lastActive});
				return self.timer = clearInterval(self.timer);
			}
			else if (diff > self.defaults.interval){
				self.defaults.intervalFn.call(self, {diff: diff, time: time, lastActive: self.defaults.lastActive});
			}

			// Rebind mouse tracking
			return self.bind();
		},

		// Rebinds activity events 
		bind: function(){
			var self = this;
			$(window).unbind('.activity').one('mousemove.activity keyup.activity', function(event){
				self.defaults.lastActive = event.timeStamp;
			});
			return self;
		}
	};
})(jQuery);
