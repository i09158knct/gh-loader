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
          'simplemocha'
        ]


    coffee:
      build:
        expand: true
        cwd: 'src/'
        src: '**/*.coffee'
        dest: 'lib/'
        ext: '.js'


    simplemocha:
      options:
        reporter: 'spec'
        compilers: ['coffee:coffee-script']
      all: ['test/**/*.coffee']



  grunt.loadNpmTasks task for task in [
    'grunt-contrib-coffee'
    'grunt-contrib-watch'
    'grunt-simple-mocha'
  ]



  grunt.registerTask name, targets for name, targets of {
    'default': ['watch']
    'test': ['simplemocha']
  }
