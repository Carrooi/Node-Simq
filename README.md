# SimQ - Common js module loader for browser (Simple reQuire)

Join and minify all your javascript files into one (even remote ones) and use them in browser just like in node server.
Same also for your style files.

## Changelog

Changelog is in the bottom of this readme.

## Supported files

Javascript:

* .js (plain javascript)
* .json
* .coffee ([coffee-script](http://coffeescript.org/))
* .ts ([TypeScript](http://www.typescriptlang.org/))

Styles:

* .less ([Less](http://lesscss.org/))
* .scss ([Sass](http://sass-lang.com/))
* .styl ([Stylus](http://learnboost.github.io/stylus/))

Templates:

* .eco ([eco](https://npmjs.org/package/eco), [documentation](https://github.com/sstephenson/eco/blob/master/README.md))

Unfortunately typescript is really slow for processing by SimQ. This is because typescript does not provide any
public API for other programmers, so there is just some slow workaround. This is really good point to use cache (see below).

## Installing

`terminal`:
```
$ npm install -g simq
```

## Creating application

`terminal`:
```
$ simq create name-of-my-new-application
```

This will create base and default skeleton for your new application.

## Configuration

SimQ using [easy-configuration](https://npmjs.org/package/easy-configuration) module for configuration and configuration
is loaded from json file. Default path for config file is `./config/setup.json`.

There are several sections in your config files, but the main one is section `packages`. This section holds information
about your modules and external libraries which will be packed into your final javascript or css file.
The name `packages` also suggests, that you can got more independent packages in one application.

`./config/setup.json`:
```
{
	"packages": {
		"nameOfYourFirstPackage": {
			"application": "./path/to/the/result/javascript/file.js"
			"modules": [
				"./my/first/module.coffee",
				"./my/second/module.js",
				"./my/third/module.ts",
				"./my/other/modules/*.coffee",
				"./even/more/modules/here/*.<(coffee|js|ts)$>",
				"./libs/jquery/jquery.js"
			],
			"libraries": {
				"begin": [
					"./some/external/library/in/the/beginning/of/the/result/file.js",
					"http://some.library/in/remote/server.js",
					"./and/some/other/files/*.js"
				],
				"end": [
					"./some/external/library/in/the/end/of/the/result/file.js"
				]
			}
		},
		"nameOfYourSecondPackage": {

		}
	}
}
```

This is the basic configuration, where you can see, how to load your modules and libraries. Plus modules and libraries
can be loaded with one by one or with asterisk or with regular expression, which have to be enclosed in <> (see full documentation of
[fs-finder](https://npmjs.org/package/fs-finder)).

If you are programing in plain javascript, maybe it will be enough for you, to define just base main js file. This is
because of SimQ automatically looks for dependencies and include other dependent files automatically. Now this is only for
.js files.

## External libraries

In example above, you could see `libraries` section with two sub sections `begin` and `end`. There you can set some external
libraries and their position in result file (beginning or the end of the file).

For libraries on remote server you can use http or https protocol.

## Styles

If you are using some CSS framework, you can let SimQ to handle these files too. Styles definitions are also in packages
and it is good to separate javascript application into one package and your styles into another, but in this example, we
will add styles definition into our first package.

`./config/setup.json`:
```
{
	"nameOfYourFirstModule": {
		"style": {
			"in": "./css/style.less",
			"out": "./css/style.css"
		}
	}
}
```

Based on file extension in `in` variable, the right css framework will be chosen.

## Templates

SimQ currently supports only [eco](https://npmjs.org/package/eco) templating system. Template files are defined in `modules`
section and you can use them just like every other module (see below).

There is also configuration which can save you few characters and wrap your eco templates automatically into jquery.

`./config/setup.json`:
```
{
	"packages": {

	},
	"template": {
		"jquerify": true
	}
}
```

## Building application

There are three options how to build your application: build to disk, watch automatically for changes and create server.

`terminal`:
```
$ cd /var/www/my-application
$ simq build
```

Or auto watching for changes:

`terminal`:
```
$ simq watch
```

Or server:

`terminal`:
```
$ simq server
```

## Server

Server has got it's own setup in your config file. You can set port of your server (default is 3000) and custom routes.

`./config/setup.json`:
```
{
	"server": {
		"port": 4000
	},
	"routes": {
		"main": "./index.html",
		"prefix": "app/",
		"routes": {
			"data-in-directory": "./someDataOnMyDisk",
			"source-file": "./someRandomFileOnMyDisk"
		}
	}
}
```

Both these sections server and routes are top level sections in config file (like packages section).

In routes section, we've set main index html file (default is `./public/index.html`), prefix for our application and routes.
If you set prefix, then every route url will be prefixed with it (default is `/`). And I guess that routes doesn't need any other explanation.

SimQ will also automatically set routes for your result javascript and style files.

In this example there will be just three urls (if index.html file exists):
* http://localhost:4000/app/
* http://localhost:4000/app/data-in-directory/<some file>
* http://localhost:4000/app/source-file

## Using modules

In your application you can use modules you defined just like you used to in node js.

`index.html`:
```
<script type="text/javascript" src="path/to/the/result/javascript/file.js"></script>
<script type="text/javascript">
	(function() {
		var Application = require('/my/first/module');

		this.app = new Application;
	}).call(window);
</script>
```

Here we created instance of my/first/module and stored it in window object (window.app).

Paths for modules have to be absolute from directory where you run `simq build` command. Exception are other modules,
if you want to use module inside another module, you can require them also relatively.

File extensions are also optional.

`lib/form.coffee`:
```
var FormValidator = require('./validator');
var SomethingElse = require('../../SomethingElseWithExtension.js');
```

## npm modules

You can also use modules from npm, but be carefully with this, because of usages of internal modules, which are not
implemented in browser or in SimQ (see compatibility section bellow).

`terminal`:
```
$ cd /var/www/my-application
$ npm install moment
```

`lib/form.coffee`:
```
var moment = require('moment');
```

If your application is written in coffee-script or in typescript, you have to add paths for these npm modules into modules
section. You don't have to do this if your application is in plain javascript.

## Aliases

Maybe you will want to shorten some frequently used modules like jQuery. For example our jquery is in ./lib/jquery directory,
so every time we want to use jquery, we have to write `require('/lib/jquery/jquery')`. Solution for this is to use aliases.

`./config/setup.json`:
```
{
	"nameOfYourFirstModule": {
		"aliases": {
			"jquery": "/lib/jquery/jquery"
		}
	}
}
```

Now you can use `require('jquery')`.

## Run automatically

It would be great if some modules can be started automatically after script is loaded to the page. You can got for example
one Bootstrap.js module, which do not export anything but just load for example Application.js module and prepare your
application. With this in most cases you don't have to got any javascript code in your HTML files!

`./config/setup.json`:
```
{
	"nameOfYourFirstModule": {
		"run": [
			"/app/setup",
			"/app/Bootstrap"
		]
	}
}
```

It is also possible to combine this `run` section with your own code. Just need to enclose it into `<>`.

`./config/setup.json`:
```
{
	"nameOfYourFirstModule": {
		"run": [
			"/app/setup",
			"<my.own.code();>",
			"/app/Bootstrap"
		]
	}
}
```

## Base namespace

If you have got more packages in your application, then writing some paths may be boring. Good example is when you rewriting
your application and when you have got your new js files for example in `./_NEW_` directory. It is not good to write
anything like this: `require('_NEW_/app/Bootstrap')`. So you can set base "namespace" of every package.

`./config/setup.json`:
```
{
	"nameOfYourFirstModule": {
		"base": "./_NEW_/"
	}
}
```

## Changing config path

`terminal`:
```
$ simq build --config my/own/path/to/config.json
```

## Debug mode

In default, SimQ automatically minify all your scripts and styles, but for developer it would be better to see not-minified
versions.

Only thing what you will need to do, is add new section to your config file.

`./config/setup.json`:
```
{
	"packages": {

    },
	"debugger": {
		"styles": true,
		"scripts": false
	}
}
```

## Verbose mode

SimQ can also tell you some more information in command line.

```
$ simq server -v
```

## Skip packages

If you want to temporary disable some packages from processing by SimQ, you can set `skip` option for this package in
your config file.


`./config/setup.json`:
```
{
	"nameOfYourFirstModule": {
		"skip": true
	}
}
```

## Caching

In large applications or in applications with typescript (explanation above) it is good to turn on cache. SimQ using
[cache-storage](https://npmjs.org/package/cache-storage) module.

`./config/setup.json`:
```
{
	"cache": {
		"directory": "./temp"
	}
}
```

Now when there is request for rebuild application, SimQ will first try to load result files (compiled) from cache and
only if they are not in cache, they will be processed and saved to cache. Next time there is no need to recompile every
file again, so they will be loaded from cache.

This is little bit harder with styles, because they importing other files into itself, so cache do not know which files
must be invalidated. If you also want to use cache in styles, you have to define dependent files in your config file.
Luckily you don't have to write every file on your own, but let [fs-finder](https://npmjs.org/package/fs-finder) do
the job for you.

`./config/setup.json`:
```
{
	"nameOfYourFirstModule": {
		"style": {
			"in": "./css/style.less",
			"out": "./css/style.css",
			"dependencies": [
				"./css/<*.less$>"
			]
		}
	}
}
```

## Compatibility with node

Global objects [link](http://nodejs.org/api/globals.html):
* require: yes
* require.resolve: yes
* require.cache: yes
* __filename: yes
* __dirname: yes
* module: yes (partially)
* exports: yes

Module object:
* module.exports: yes
* module.require: no
* module.id: yes
* module.filename: yes
* module.loaded: yes
* module.parent: no
* module.children: no

## Source maps

Less can also generate source maps with sass source maps syntax. If you want this function, you have to turn on debug
mode for styles.

`./config/setup.json`:
```
{
	"debugger": {
		"styles": true,
		"sourceMap": true
	}
}
```

## Changelog list

* 4.1.1
	+ Bug with building application

* 4.1.0
	+ Added ability to run own code from run section

* 4.0.0
	+ Bugs
	+ Optimizations in configuration
	+ Updated for new version of [easy-configuration](https://npmjs.org/package/easy-configuration)
	+ Bugs in tests
	+ Added skip option

* 3.9.2
	+ Added tests for styles
	+ Bug with eco templates
	+ Optimizations

* 3.9.1
	+ auto 'module.exports' for json files

* 3.9.0
	+ Base namespace is applied also for results files and style files (BC break)
	+ Bug with styles and application building
	+ Some optimizations

* 3.8.0
	+ Many typos in readme
	+ Files are compiled with [source-compiler](https://npmjs.org/package/source-compiler)
	+ Added other tests
	+ Optimizations
	+ Some bugs in building application

* 3.7.3
	+ Typos in readme (compatibility mode)

* 3.7.2
	+ Typos in readme

* 3.7.1
	+ Added information about compatibility with node
	+ Exposed require.resolve function
	+ Exposed require.cache object

* 3.7.0
	+ Module objects is almost the same like in node
	+ Added __filename and __dirname variables

* 3.6.0
	+ Added server command
	+ Added verbose option
	+ Updated sandbox

* 3.5.2
	+ Section run is compiled before libraries - end

* 3.5.1
	+ Bug with generating modules

* 3.5.0
	+ Libs section renamed to libraries
	+ Tests can be run throw `npm test` command

* 3.4.0:
	+ Added changelog
	+ Created some tests for building js application
	+ Fixed bugs in js building