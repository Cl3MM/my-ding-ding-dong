class Routes
  constructor: ($urlRouterProvider, $stateProvider, $locationProvider)->
    moment.locale 'fr'

    $locationProvider.html5Mode true

    $stateProvider.state 'bookings',
      url: '/'
      templateUrl: 'client/bookings/views/index.html'
      controller: 'bookingsController'
      resolve:
        currentUser: [ '$q', ($q)->
          unless Meteor.userId()
            console.log "User not logged in :("
            $q.reject 'AUTH_REQUIRED'
          else
            console.log "User logged in !!!"
            return $q.resolve()
        ]

    $urlRouterProvider.otherwise '/'

angular
  .module 'huezNg'
  .config [ '$urlRouterProvider', '$stateProvider', '$locationProvider', Routes]

