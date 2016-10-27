module.exports = (grunt) ->
	# Project configuration.
	grunt.initConfig
		pkg: grunt.file.readJSON('package.json')
		banner: """
/*
 * <%= pkg.name %> <%= pkg.version %> ( <%= grunt.template.today( 'yyyy-mm-dd' )%> )
 * <%= pkg.homepage %>
 *
 * Released under the MIT license
 * <%= pkg.homepage %>/blob/master/LICENSE
 *
 * Maintained by <%= pkg.maintainers.name %> ( <%= pkg.maintainers.url %> )
*/
"""
		watch:
			module:
				files: ["_src/**/*.coffee"]
				tasks: [ "coffee:base" ]

		coffee:
			base:
				expand: true
				cwd: '_src',
				src: ["**/*.coffee"]
				dest: ''
				ext: '.js'

		clean:
			base:
				src: [ "lib", "test", "*.js" ]

		includereplace:
			pckg:
				options:
					globals:
						version: "<%= pkg.version %>"

					prefix: "@@"
					suffix: ''

				files:
					"index.js": ["index.js"]


		usebanner:
			options:
				banner: "<%= banner %>"
			base:
				files:
					"index.js": ["index.js"]
					"lib/node_cache.js": ["lib/node_cache.js"]
					"test/node_cache-test.js": ["test/node_cache-test.js"]


		mochacli:
			options:
				require: [ "should", "coffee-coverage/register-istanbul" ]
				reporter: "spec"
				bail: false
				timeout: 3000
				slow: 3
				compilers: "coffee:coffee-script/register"

			main:
				src: [ "_src/test/mocha_test.coffee" ]

	# Load npm modules
	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-clean"
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-include-replace"
	grunt.loadNpmTasks "grunt-banner"
	grunt.loadNpmTasks "grunt-mocha-cli"

	# ALIAS TASKS
	grunt.registerTask "default", "build"
	grunt.registerTask "clear", [ "clean:base" ]
	grunt.registerTask "test", "mochacli:main"
	# Shortcuts
	grunt.registerTask "b", "build"
	grunt.registerTask "w", "watch"
	# build the project
	grunt.registerTask "build", [ "clear", "coffee:base", "usebanner:base", "includereplace:pckg" ]
