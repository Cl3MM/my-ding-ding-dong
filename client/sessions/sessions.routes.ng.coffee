class Routes
  constructor: ($stateProvider)->
    $stateProvider.state 'login',
      url: '/login'
      #template: "<h1>prout</h1>"
      templateUrl: 'client/sessions/views/login.html'

angular
  .module 'huezNg.sessions'
  .config [ '$stateProvider', Routes]


