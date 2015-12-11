if Meteor.isClient

  class Init
    constructor: ->
      moment.locale 'fr'

  angular
    .module 'huezNg'
    .run [ Init ]

