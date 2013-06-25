define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'aloha'
  #'mathjax'
], ($, _, Backbone, Marionette, Aloha) ->

  return Marionette.ItemView.extend
    # **NOTE:** This template is not wrapped in an element
    template: () -> throw 'You need to specify a template, modelKey, and optionally alohaOptions'
    modelKey: null
    alohaOptions: null
    loaded: false

    initialize: () ->
      # Update the view when the content is done loading (remove progress bar)
      @listenTo(@model, 'loaded', @render)

      @listenTo @model, "change:#{@modelKey}", (model, value, options) =>
        return if options.internalAlohaUpdate

        alohaId = @$el.attr('id')
        # Sometimes Aloha hasn't loaded up yet
        if alohaId and @$el.parents().get(0)
          alohaEditable = Aloha.getEditableById(alohaId)
          editableBody = alohaEditable.getContents()
          if value isnt editableBody then alohaEditable.setContents(value)
        else
          @$el.empty().append(value)

    onRender: () ->
      # Only load once
      if @loaded then return

      # Auto save after the user has stopped making changes
      updateModelAndSave = =>
        alohaId = @$el.attr('id')
        # Sometimes Aloha hasn't loaded up yet
        # Only save when the editable has changed
        if alohaId
          alohaEditable = Aloha.getEditableById(alohaId)
          editableBody = alohaEditable.getContents()
          # Change the contents but do not update the Aloha editable area
          @model.set(@modelKey, editableBody, {internalAlohaUpdate: true})

      if @model.loaded and document.contains(@el)
        @loaded = true

        # Once Aloha has finished loading enable
        @$el.addClass('disabled')
        Aloha.ready =>
          # Wait until Aloha is started before loading MathJax.
          MathJax?.Hub.Configured()

          @$el.aloha(@alohaOptions)
          @$el.removeClass('disabled')

          # Grr, the `aloha-smart-content-changed` can only be listened to globally
          # (via `Aloha.bind`) instead of on each editable.
          #
          # This is problematic when we have multiple Aloha editors on a page.
          # Instead, autosave after some period of inactivity.
          @$el.on('blur', updateModelAndSave)

    onShow: () ->
      @onRender()
