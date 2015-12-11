if Meteor.isClient

  class Routes
    constructor: ($urlRouterProvider, $stateProvider, $locationProvider)->
      moment.locale 'fr'

      $locationProvider.html5Mode true
      $stateProvider.state 'bookings',
        url: '/reservations'
        templateUrl: 'client/bookings/views/index.html'
        controller: 'bookingsController'
          ###.state 'partyDetails',
            url: '/parties/:partyId'
            templateUrl: 'party-details.html'
            controller: 'PartyDetailsCtrl'
          ###
      $urlRouterProvider.otherwise '/reservations'

  angular
    .module 'huezNg'
    .config [ '$urlRouterProvider', '$stateProvider', '$locationProvider', Routes]

