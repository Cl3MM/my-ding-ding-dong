class Routes
  constructor: ($urlRouterProvider, $stateProvider, $locationProvider)->
    moment.locale 'fr'

    $locationProvider.html5Mode true

    $stateProvider.state 'bookings',
      url: '/'
      templateUrl: 'client/bookings/views/index.html'
      controller: 'bookingsController'

    $urlRouterProvider.otherwise '/'

angular
  .module 'huezNg'
  .config [ '$urlRouterProvider', '$stateProvider', '$locationProvider', Routes]

