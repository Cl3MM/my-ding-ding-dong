class Init
  constructor: ($rootScope, $state)->
    moment.locale 'fr'

    $rootScope.$on '$stateChangeStart', @stateChangeStart
    $rootScope.$on '$stateChangeSuccess', @stateChangeSuccess
    $rootScope.$on '$stateChangeError', @stateChangeError
    $rootScope.$on '$stateNotFound', @stateNotFound

    $rootScope.$on '$stateChangeError', (event, toState, toParams, fromState, fromParams, error)->
      if error is 'AUTH_REQUIRED'
        console.log 'Auth required'
        $state.go 'login'


  stateChangeStart: (ev, toState, toParams, fromState, fromParams)->
    console.log 'State change start',
      event      : ev
      toState    :toState
      toParams   :toParams
      fromState  :fromState
      fromParams :fromParams

  stateChangeSuccess: (ev, toState, toParams, fromState, fromParams)->
    console.log 'State change success',
      event      : ev
      toState    :toState
      toParams   :toParams
      fromState  :fromState
      fromParams :fromParams

  stateChangeError: (ev, toState, toParams, fromState, fromParams, error)->
    console.error 'State change error'
    console.error {
      event: ev
      toState    :toState
      toParams   :toParams
      fromState  :fromState
      fromParams :fromParams
      error      :error
    }
  stateNotFound: (ev, unfoundState, fromState, fromParams)->
    console.error 'State change not found'
    console.error {
      event        : ev
      unfoundState :unfoundState
      fromState    :fromState
      fromParams   :fromParams
    }

angular
  .module 'huezNg'
  .run [ '$rootScope', '$state',  Init ]

