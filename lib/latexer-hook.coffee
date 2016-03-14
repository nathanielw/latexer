{CompositeDisposable} = require 'atom'
LabelView = require './label-view'
CiteView = require './cite-view'
TermView = require './term-view'

module.exports =
  class LatexerHook
    beginRex: /\\begin{([^}]+)}/
    mathRex: /(\\+)\[/
    refRex: /\\\w*ref({|{[^}]+,)$/
    citeRex: /\\(cite|textcite|onlinecite|citet|citep|citet\*|citep\*)(\[[^\]]+\])?({|{[^}]+,)$/
    termRex: /\\(gls\w*|acrlong|acrshort|acrfull)({|{[^}]+,)$/
    constructor: (@editor) ->
      @disposables = new CompositeDisposable
      @disposables.add @editor.onDidChangeTitle => @subscribeBuffer()
      @disposables.add @editor.onDidChangePath => @subscribeBuffer()
      @disposables.add @editor.onDidSave => @subscribeBuffer()

      @disposables.add @editor.onDidDestroy(@destroy.bind(this))
      @subscribeBuffer()
      @lv = new LabelView
      @cv = new CiteView
      @tv = new TermView

    destroy: ->
      @unsubscribeBuffer()
      @disposables.dispose()
      @lv?.hide()
      @cv?.hide()
      @tv?.hide()


    subscribeBuffer: ->
      @unsubscribeBuffer()
      return unless @editor?
      title = @editor?.getTitle()
      return unless title? and title.match(/\.tex$/)
      @buffer = @editor.getBuffer()
      @disposableBuffer = @buffer.onDidStopChanging => @editorHook()

    unsubscribeBuffer: ->
      @disposableBuffer?.dispose()
      @buffer = null

    refCiteCheck: (editor, refOpt, citeOpt, termOpt)->
      pos = editor.getCursorBufferPosition().toArray()
      line = editor.getTextInBufferRange([[pos[0], 0], pos])
      if refOpt and (match = line.match(@refRex))
        @lv.show(editor)
      if citeOpt and (match = line.match(@citeRex))
        @cv.show(editor)
      if citeOpt and (match = line.match(@termRex))
        @tv.show(editor)

    environmentCheck: (editor)->
      pos = editor.getCursorBufferPosition().toArray()
      return if pos[0] <= 0
      previousLine = editor.lineTextForBufferRow(pos[0]-1)
      if (match = @beginRex.exec(previousLine))
        beginText = "\\begin{#{match[1]}}"
        endText = "\\end{#{match[1]}}"
        beginTextRegify = beginText.replace(/([()[{*+.$^\\|?])/g, "\\$1")
        beginTextRex = new RegExp beginTextRegify, "gm"
        endTextRegify = endText.replace(/([()[{*+.$^\\|?])/g, "\\$1")
        endTextRex = new RegExp endTextRegify, "gm"
      else if (match = @mathRex.exec(previousLine)) and match[1].length % 2
        beginText = "\\["
        endText = "\\]"
        beginTextRex = new RegExp "\\\\\\[", "gm"
        endTextRex = new RegExp "\\\\\\]", "gm"
      else
        return
      lineCount = editor.getLineCount()
      preText= editor.getTextInBufferRange([[0,0], [pos[0],0]]).replace /%.+$/gm,""
      remainingText = editor.getTextInBufferRange([[pos[0],0],[lineCount+1,0]]).replace /%.+$/gm,""
      balanceBefore = (preText.match(beginTextRex)||[]).length - (preText.match(endTextRex)||[]).length
      balanceAfter = (remainingText.match(beginTextRex)||[]).length - (remainingText.match(endTextRex)||[]).length
      return if balanceBefore + balanceAfter < 1
      posBefore = editor.getCursorBufferPosition()
      editor.insertText endText
      editor.moveUp 1
      editor.moveToEndOfLine()
      editor.insertText "\n"

    editorHook: (editor = @editor)->
      envOpt = atom.config.get "latexer.autocomplete_environments"
      refOpt = atom.config.get "latexer.autocomplete_references"
      citeOpt = atom.config.get "latexer.autocomplete_citations"
      termOpt = atom.config.get "latexer.autocomplete_terms"
      @refCiteCheck(editor, refOpt, citeOpt, termOpt) if refOpt or citeOpt or termOpt
      @environmentCheck(editor) if envOpt
