module.exports = (grunt) ->
  grunt.initConfig
    watch:
      coffee:
        files: [
          '<%= coffee.build.cwd %><%= coffee.build.src %>'
          'Gruntfile.coffee'
        ]
        tasks: ['coffee']
      test:
        files: [
          '<%= coffee.build.dest %>**/*'
          'test/**/*'
        ]
        tasks: [
          'shell:test'
        ]


    coffee:
      build:
        expand: true
        cwd: 'src/'
        src: '**/*.coffee'
        dest: 'lib/'
        ext: '.js'


    shell:
      test:
        command: do -> [
          './node_modules/mocha/bin/mocha'
          'test/main-spec.coffee'
          '--compilers coffee:coffee-script'
          '--reporter spec'
        ].join ' '
        options:
          stdout: true
          stderr: true
          failOnError: true



  [
    'grunt-shell'
    'grunt-contrib-coffee'
    'grunt-contrib-watch'
  ].forEach grunt.loadNpmTasks

  grunt.registerTask 'default', [
    'watch'
  ]
