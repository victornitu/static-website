{promisify}           = require 'util'
{readFile, writeFile} = require 'fs'
sass                  = require 'node-sass'
pug                   = require 'pug'
yaml                  = require 'js-yaml'
coffeescript          = require 'coffeescript'

read        = promisify readFile
write       = promisify writeFile
render      = promisify sass.render

readYaml = (path) ->
  data = await read path, 'utf8'
  yaml.safeLoad data

readConfig = (name) -> readYaml "config/#{name}.yaml"
readI18n   = (name) -> readYaml "i18n/#{name}.yaml"

writeHtml = (name, language, html) ->
  await write "dist/#{language}/#{name}.html", html

writeCss = (name) ->
  file = "src/styles/#{name}.scss"
  style = await render {file}
  await write "dist/styles/#{name}.css", style.css

writeJs = (name) ->
  file = "src/scripts/#{name}.coffee"
  code = await read file, 'utf8'
  options = transpile: presets: ['env']
  script =  coffeescript.compile code, options
  await write "dist/scripts/#{name}.js", script

Compiler = (page, common, languages) ->
  compiledFn = pug.compileFile "src/#{page}.pug"
  (language) ->
    try
      i18n = await readI18n language
      await writeHtml page, language, compiledFn {page, common, languages, i18n}
      console.log 'Page', page, 'compiled for language', language
    catch err
      console.error 'Failed to compile', page, 'for', language
      console.error 'Error:', err

main = ->
  console.log 'Compile website'
  {languages, pages} = await readConfig 'default'
  console.log 'Config loaded'
  console.log 'Languages used:', languages
  common = await readI18n 'common'
  console.log 'Common loaded'
  await writeCss 'main'
  console.log 'Main css compiled'
  await writeJs 'main'
  console.log 'Main js compiled'
  await Promise.all pages.map (p) ->
    compilePage = Compiler p, common, languages
    try
      await Promise.all languages.map compilePage
    catch err
      console.error 'Failed to compile', p
      console.error 'Error:', err

main()
