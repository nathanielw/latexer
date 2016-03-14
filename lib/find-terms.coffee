fsPlus = require 'fs-plus'
fs = require 'fs-plus'
path = require 'path'

module.exports =
FindTerms =
  getTermsByText: (text, file = "") ->
    termRex = /\\(?:newglossaryentry|newacronym)(?:\[.*\])?{([^}]+)}/g
    matches = []
    while (match = termRex.exec(text))
      matches.push {term: match[1]}
    return matches unless file?
    inputRex = /\\(input|include){([^}]+)}/g
    while (match = inputRex.exec(text))
      matches = matches.concat(@getTerms(@getAbsolutePath(file, match[2])))
    matches

  getTerms: (file) ->
    if not fsPlus.isFileSync(file) #if file is not there try add possible extensions
      file = fsPlus.resolveExtension(file, ['tex'])
    return [] unless fsPlus.isFileSync(file)
    text = fs.readFileSync(file).toString()
    @getTermsByText(text, file)

  getAbsolutePath: (file, relativePath) ->
    if (ind = file.lastIndexOf(path.sep)) isnt file.length
      file = file.substring(0,ind)
    path.resolve(file, relativePath)
