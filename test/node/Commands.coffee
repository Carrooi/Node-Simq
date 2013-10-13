expect = require('chai').expect
path = require 'path'
Finder = require 'fs-finder'
rimraf = require 'rimraf'
fs = require 'fs'
Compiler = require 'source-compiler'
http = require 'http'

SimQ = require '../../lib/SimQ'
Commands = require '../../lib/Commands'
Factory = require '../../lib/Package/Factory'
Configurator = require '../../lib/Config/Configurator'

dir = path.resolve(__dirname + '/../data')

simq = null
commands = null
server = null

describe 'Commands', ->

	describe '#create()', ->

		beforeEach( ->
			simq = new SimQ(dir)
			commands = new Commands(simq)
		)

		it 'should throw an error if path already exists', (done) ->
			commands.create('package').fail( (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal('Directory package already exists.')
				done()
			).done()

		it 'should create new project from sandbox', (done) ->
			commands.create('test').then( ->
				files = Finder.findFiles(dir + '/test/*')
				expect(files).to.be.eql([
					dir + '/test/config/setup.json'
					dir + '/test/css/style.less'
					dir + '/test/package.json'
					dir + '/test/public/application.js'
					dir + '/test/public/index.html'
				])
				rimraf(dir + '/test', -> done())
			).done()

		it 'should build application from sandbox', (done) ->
			commands.create('test').then( ->
				s = new SimQ(dir + '/test')
				c = new Commands(s)

				configurator = new Configurator(dir + '/test/config/setup.json')
				pckg = Factory.create(s.basePath, configurator.load().packages.application)
				s.addPackage('test', pckg)

				c.build().then( ->
					expect(fs.readFileSync(dir + '/test/public/application.js', encoding: 'utf8')).to.have.string("'/package.json'")
					expect(fs.readFileSync(dir + '/test/public/style.css', encoding: 'utf8')).to.be.equal('')
					rimraf(dir + '/test', -> done())
				).done()
			).done()

	describe '#clean()', ->
		it 'should remove all files created by simq', (done) ->
			simq = new SimQ(dir)
			commands = new Commands(simq)

			commands.create('test').then( ->
				s = new SimQ(dir + '/test')
				c = new Commands(s)

				configurator = new Configurator(dir + '/test/config/setup.json')
				pckg = Factory.create(s.basePath, configurator.load().packages.application)
				s.addPackage('test', pckg)

				c.build().then( ->
					fs.writeFileSync(dir + '/cache/__' + Compiler.CACHE_NAMESPACE + '.json', '{}')
					c.clean('../cache')

					expect(fs.existsSync(dir + '/test/public/application.js')).to.be.false
					expect(fs.existsSync(dir + '/test/public/style.css')).to.be.false
					expect(fs.existsSync(dir + '/cache/__' + Compiler.CACHE_NAMESPACE + '.json')).to.be.false

					rimraf(dir + '/test', -> done())
				).done()
			).done()

	describe '#server()', ->

		beforeEach( ->
			simq = new SimQ(dir + '/package')
			commands = new Commands(simq)
		)

		afterEach( ->
			server.close()
		)

		it 'should create default server for application', (done) ->
			server = commands.server()

			http.get('http://localhost:3000', (res) ->
				data = []
				res.setEncoding('utf8')
				res.on 'data', (chunk) -> data.push(chunk)
				res.on 'end', ->
					data = data.join('')
					expect(data).to.have.string('Hello word')
					done()
			)

		it 'should create default server on another port', (done) ->
			server = commands.server(null, null, null, 8000)

			http.get('http://localhost:8000', (res) ->
				data = []
				res.setEncoding('utf8')
				res.on 'data', (chunk) -> data.push(chunk)
				res.on 'end', ->
					data = data.join('')
					expect(data).to.have.string('Hello word')
					done()
			)

		it 'should create server with prefix', (done) ->
			server = commands.server('package')

			http.get('http://localhost:3000/package', (res) ->
				data = []
				res.setEncoding('utf8')
				res.on 'data', (chunk) -> data.push(chunk)
				res.on 'end', ->
					data = data.join('')
					expect(data).to.have.string('Hello word')
					done()
			)

		it 'should create server with different main file', (done) ->
			server = commands.server(null, './public/default.html')

			http.get('http://localhost:3000', (res) ->
				data = []
				res.setEncoding('utf8')
				res.on 'data', (chunk) -> data.push(chunk)
				res.on 'end', ->
					data = data.join('')
					expect(data).to.have.string('Some default page')
					done()
			)

		it 'should create server with some route', (done) ->
			server = commands.server(null, null, 'jquery.js': './public/jquery.js')

			http.get('http://localhost:3000/jquery.js', (res) ->
				data = []
				res.setEncoding('utf8')
				res.on 'data', (chunk) -> data.push(chunk)
				res.on 'end', ->
					data = data.join('')
					expect(data).to.be.equal('// This is not jQuery')
					done()
			)

		it 'should create server with route to directory', (done) ->
			server = commands.server(null, null, 'public': './public')

			http.get('http://localhost:3000/public/jquery.js', (res) ->
				data = []
				res.setEncoding('utf8')
				res.on 'data', (chunk) -> data.push(chunk)
				res.on 'end', ->
					data = data.join('')
					expect(data).to.be.equal('// This is not jQuery')
					done()
			)

		it 'should create server with route to directory and prefix', (done) ->
			server = commands.server('package', null, 'public': './public')

			http.get('http://localhost:3000/package/public/jquery.js', (res) ->
				data = []
				res.setEncoding('utf8')
				res.on 'data', (chunk) -> data.push(chunk)
				res.on 'end', ->
					data = data.join('')
					expect(data).to.be.equal('// This is not jQuery')
					done()
			)

		it 'should create server with package (js)', (done) ->
			pckg = simq.addPackage('app')
			pckg.setApplication('./public/application.js')
			pckg.addModule('./app/Application.coffee')

			server = commands.server()

			http.get('http://localhost:3000/public/application.js', (res) ->
				data = []
				res.setEncoding('utf8')
				res.on 'data', (chunk) -> data.push(chunk)
				res.on 'end', ->
					data = data.join('')
					expect(data).to.have.string("'/app/Application.coffee'")
					done()
			)

		it 'should create server with package (js) and prefix', (done) ->
			pckg = simq.addPackage('app')
			pckg.setApplication('./public/application.js')
			pckg.addModule('./app/Application.coffee')

			server = commands.server('package')

			http.get('http://localhost:3000/package/public/application.js', (res) ->
				data = []
				res.setEncoding('utf8')
				res.on 'data', (chunk) -> data.push(chunk)
				res.on 'end', ->
					data = data.join('')
					expect(data).to.have.string("'/app/Application.coffee'")
					done()
			)

		it 'should create server with package (css)', (done) ->
			pckg = simq.addPackage('app')
			pckg.setStyle('./css/style.less', './public/style.css')

			server = commands.server()

			http.get('http://localhost:3000/public/style.css', (res) ->
				data = []
				res.setEncoding('utf8')
				res.on 'data', (chunk) -> data.push(chunk)
				res.on 'end', ->
					data = data.join('')
					expect(data).to.be.equal('body {\n  color: #000000;\n}\n')
					done()
			)

		it 'should create server with package (css) and prefix', (done) ->
			pckg = simq.addPackage('app')
			pckg.setStyle('./css/style.less', './public/style.css')

			server = commands.server('package')

			http.get('http://localhost:3000/package/public/style.css', (res) ->
				data = []
				res.setEncoding('utf8')
				res.on 'data', (chunk) -> data.push(chunk)
				res.on 'end', ->
					data = data.join('')
					expect(data).to.be.equal('body {\n  color: #000000;\n}\n')
					done()
			)

		it 'should create server from sandbox (main)', (done) ->
			s = new SimQ(dir)
			c = new Commands(s)

			c.create('test').then( ->
				simq = new SimQ(dir + '/test')
				commands = new Commands(simq)

				configurator = new Configurator(dir + '/test/config/setup.json')
				pckg = Factory.create(simq.basePath, configurator.load().packages.application)
				simq.addPackage('test', pckg)

				server = commands.server()

				http.get('http://localhost:3000', (res) ->
					data = []
					res.setEncoding('utf8')
					res.on 'data', (chunk) -> data.push(chunk)
					res.on 'end', ->
						data = data.join('')
						expect(data).to.have.string('<!-- your content -->')

						rimraf(dir + '/test', -> done())
				)
			).done()

		it 'should create server from sandbox (js)', (done) ->
			s = new SimQ(dir)
			c = new Commands(s)

			c.create('test').then( ->
				simq = new SimQ(dir + '/test')
				commands = new Commands(simq)

				configurator = new Configurator(dir + '/test/config/setup.json')
				pckg = Factory.create(simq.basePath, configurator.load().packages.application)
				simq.addPackage('test', pckg)

				server = commands.server()

				http.get('http://localhost:3000/public/application.js', (res) ->
					data = []
					res.setEncoding('utf8')
					res.on 'data', (chunk) -> data.push(chunk)
					res.on 'end', ->
						data = data.join('')
						expect(data).to.have.string("'/package.json'")

						rimraf(dir + '/test', -> done())
				)
			).done()

		it 'should create server from sandbox (css)', (done) ->
			s = new SimQ(dir)
			c = new Commands(s)

			c.create('test').then( ->
				simq = new SimQ(dir + '/test')
				commands = new Commands(simq)

				configurator = new Configurator(dir + '/test/config/setup.json')
				pckg = Factory.create(simq.basePath, configurator.load().packages.application)
				simq.addPackage('test', pckg)

				server = commands.server()

				http.get('http://localhost:3000/public/style.css', (res) ->
					data = []
					res.setEncoding('utf8')
					res.on 'data', (chunk) -> data.push(chunk)
					res.on 'end', ->
						data = data.join('')
						expect(data).to.be.equal('')

						rimraf(dir + '/test', -> done())
				)
			).done()