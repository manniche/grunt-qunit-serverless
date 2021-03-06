path = require "path"

should = require "should"
grunt = require "grunt"

{_, async} = grunt.util

QUnitServerlessTask = require "../tasks/lib/QUnitServerlessTask"

describe "QUnitServerlessTask", ->

	makeFakeTask = ->
		options: -> {}

	it "can load include paths", ->

		task = new QUnitServerlessTask(makeFakeTask())

		result = task._includeFilePath "someFile.txt"

		expect = path.resolve path.join(__dirname, "..", "includes", "someFile.txt")

		result.should.equal expect, "someFile.txt"

	it "can load default includes", ->

		task = new QUnitServerlessTask(makeFakeTask())

		result = task._includeDefaults()

		result.pageTemplate.should.equal task._includeFilePath("qunit-page.tpl")
		result.qunitCss.should.equal task._includeFilePath("qunit.css")
		result.qunitJs.should.equal task._includeFilePath("qunit.js")
		result.qunitBridge.should.equal task._includeFilePath("qunit-bridge.js")

	it "can register itself with grunt", ->

		should.exist QUnitServerlessTask.registerWithGrunt

		calledWithName = null
		calledWithFunc = null
		fakeGrunt = 
			registerMultiTask: (name, func) ->
				calledWithName = name
				calledWithFunc = func

		QUnitServerlessTask.registerWithGrunt(fakeGrunt)

		calledWithName.should.equal "qunit-serverless"
		should.exist calledWithFunc

	it "makes reporters classes available", ->

		thing = require "../tasks/qunit-serverless"

		should.exist thing.Reporters, "Reporters"

		should.exist thing.Reporters.Base, "BaseReporter"
		should.exist thing.Reporters.Spec, "SpecReporter"

		should.exist new thing.Reporters.Base(), "BaseReporter instance"
		should.exist new thing.Reporters.Spec(), "SpecReporter instance"

	it "can build only", (done) ->
		grunt.log.muted = true
		
		fakeGruntTask = makeFakeTask()
		fakeGruntTask.options = ->
			buildOnly: true
		# pass back a wrap up function for async()
		fakeGruntTask.async = -> 
			->
				buildCalls.should.equal 1
				# TODO: Check grunt log output?
				done()

		task = new QUnitServerlessTask(fakeGruntTask)

		buildCalls = 0
		task._build = (buildDone) ->
			buildCalls++
			buildDone null, "/some/file/path"
			

		task._runPhantom = (filePath, done) ->
			throw new Error "Should not call _runPhantom when build only is passed"

		task.run()
