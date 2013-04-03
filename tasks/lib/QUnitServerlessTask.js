var path = require("path");

var grunt = require("grunt"),
	_ = grunt.util._;

var IncludesBase = require("./IncludesBase"),
	PageBuilder = require("./PageBuilder"),
	PhantomQUnitRunner = require("./PhantomQUnitRunner");

var QUnitServerlessTask = function(task, phantomjs) {
	IncludesBase.call(this);

	this.setOptions(task);
	this.async = task.async;
	this.phantomjs = phantomjs;
};

_.extend(QUnitServerlessTask.prototype, IncludesBase.prototype);

_.extend(QUnitServerlessTask.prototype, {
	setOptions: function(task) {
		this.options = task.options(this._includeDefaults());
	},

	run: function() {
		var self = this,
			done = this.async(),
			pageBuilder = new PageBuilder(this.options);

		// Build the html page up and save it to a temp location, return a url to temp file.
		pageBuilder.build(function(err, fileCreatedPath) {
			if(err) {
				grunt.fatal(err.message);
				return done();
			}
			
			var runner = new PhantomQUnitRunner(self.phantomjs, self.options);

			// Start the phantom runner with the file path to the temp file
			runner.run(fileCreatedPath, function(err, results) {
				if(err) {
					grunt.fatal(err.message);
				}

				if(results.passed !== results.total) {
					grunt.warn("Some tests failed");
				}

				done();
			});
		});
	}
});

// A static helper method for registering
QUnitServerlessTask.registerWithGrunt = function(grunt) {

	var phantomjs = require('grunt-lib-phantomjs').init(grunt);

	grunt.registerMultiTask("qunit-serverless", "Builds up an HTML page and runs it with PhantomJS", function() {
		var task = new QUnitServerlessTask(this, phantomjs);

		task.run();
	});
};

module.exports = QUnitServerlessTask;