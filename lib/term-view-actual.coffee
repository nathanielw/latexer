{$,SelectListView} = require 'atom-space-pen-views'
FindTerms = require './find-terms'
fs = require 'fs-plus'

module.exports =
class TermsView extends SelectListView
  editor: null
  panel: null

  initialize: ->
    super
    @addClass('overlay from-top term-view')

  show: (editor) ->
    return unless editor?
    @editor = editor
    file = editor?.buffer?.file
    basePath = file?.path
    texRootRex = /%!TEX root = (.+)/g
    while(match = texRootRex.exec(@editor.getText()))
      absolutFilePath = FindTerms.getAbsolutePath(basePath,match[1])
      try
        text = fs.readFileSync(absolutFilePath).toString()
        terms = FindTerms.getTermsByText(text, absolutFilePath)
      catch error
        atom.notifications.addError('could not load content of '+ absolutFilePath, { dismissable: true })
        console.log(error)
    if terms == undefined or terms.length == 0
      terms = FindTerms.getTermsByText(@editor.getText(), basePath)
    @setItems(terms)
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @storeFocusedElement()
    @focusFilterEditor()

  hide: ->
    @panel?.hide()

  getEmptyMessage: ->
    "No terms found"

  getFilterKey: ->
    "term"

  viewForItem: ({term}) ->
     "<li>#{term}</li>"

  confirmed: ({term}) ->
    @editor.insertText term
    @restoreFocus()
    @hide()

  cancel: ->
    super
    @hide()
