# SimQ - simple require for javascript (client)

## Installing

```
$ npm install -g simq
```

## Building

Merging all files into one will be helpful for client's browser (less http requests).

SimQ will automatically merge all your files into one for you.

```
$ cd /my/project/path
$ simq build
```

## Configuration - setup.json

The only thing what SimQ needs for run, is setup.json file, which contains configuration for your application.
The example below shows full configuration.
```
#!json

{
	"main": "./Application.js",
	"modules": [
		"./app/Application.js",
		"./app/controllers/",
		"./src/*.coffee",
		"./config/database.json"
	],
	"libs": {
		"begin": [
			"./lib/jquery.js"
		],
		"end": [
			"./lib/ckeditor.js"
		]
	}
}
```

Main section holds name of final file.

Modules section is array with list of all your own modules. More information about how to properly create module is bellow.
There are three ways how to define your modules. You can specify every module manually, or you can write just path to base dirs with slash in the end - this will load all modules in this folder recursively. The last possible way is to load everything from specified folder, but only files with given extension.
Last section defines other libraries and the place where they should be inserted.

In this example you can also see all supported files: js, coffee and json.

## Module

Every module is simple javascript file. Here is example for hello word application.

```
#!javascript

// file app/helloWord.js

(function() {

	module.exports = function() {
		alert('hello word');
	};

}).call(this);
```

## Using module

```
#!html

<script type="text/javascript" src="Application.js"></script>
<script type="text/javascript">
	var hello = require('app/helloWord');

	hello();
</script>
```

You can notice that in require, we are not using any file extension - just like in node.

## Coffee script modules
If your are using coffee script, everything will be even much easier.

```
#!coffee-script

# file app/helloWord.coffee

module.exports = -> alert 'hello word'
```
As you can see, module definition is just a class (or any other code) and return statement. This is done because of coffee-script itself, which automatically wrap all your code into it's own scope.

## Watching for changes
It is also very simple to tell the SimQ to watch your files for changes. This is much easier than running 'simq build' after each change in your code.

```
$ cd /my/project/path
$ simq watch
```

## Compress result
In default, SimQ automatically compress result javascript file, but sometimes (for example for debug reasons), you may want to see it uncompressed.
This can be achieved by adding "debug" to build or watch command.

```
$ simq build --debug
```