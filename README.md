# SimQ - simple require for javascript

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
		"./app/controllers/*"
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

Modules section is array with list of all your own modules. More informations about how to properly create module is bellow.
There are two ways how to define your modules. You can specify every module manually, or you can write just path to base dirs with asterisk in the end - this will load all modules in this folder recursively.
Last section defines other libraries and the place where they should be inserted.

## Module

Every module is simple javascript file. Here is example for hello word application.

```
#!javascript

// file app/helloWord.js

(function() {

	return function() {
		alert('hello word');
	};

}).call(this);
```

## Using module

```
#!html

<script type="text/javascript" src="Application.js"></script>
<script type="text/javascript">
	require('app/helloWord')();
</script>
```

You can notice that in require, we are not using any file extension - just like in node.

## Watching for changes
It is also very simple to tell the SimQ to watch your files for changes. This is much simplier than running 'simq build' after each change in your code.

```
$ cd /my/project/path
$ simq watch
```

## Compress result
In default, SimQ automatically compress result javascript file, but sometimes (for example for debug reasons), you may want to see it uncompressed.
This can be achieved by adding "debug" to build or watch command.

```
$ simq build debug
```