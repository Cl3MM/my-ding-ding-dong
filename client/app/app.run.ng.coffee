class Init
  constructor: ($rootScope, $state)->
    moment.locale 'fr'

    $rootScope.$on '$stateChangeStart', @stateChangeStart
    $rootScope.$on '$stateChangeSuccess', @stateChangeSuccess
    $rootScope.$on '$stateChangeError', @stateChangeError
    $rootScope.$on '$stateNotFound', @stateNotFound

    $rootScope.$on '$stateChangeError', (event, toState, toParams, fromState, fromParams, error)->
      if error is 'AUTH_REQUIRED'
        $rootScope.returnToState = toState
        $rootScope.returnToStateParams = toParams
        console.log 'Auth required'
        $state.go 'login'

    Meteor.autorun ->
      console.group "Autoruning"
      console.log Meteor.user()
      console.groupEnd()
      unless Meteor.user()
        if Meteor.loggingIn()
          console.log "LoggingIn"
          if Meteor.user()
            console.log "User: #{Meteor.user()}"
            $state.go 'bookings'
          else
            console.log "go login"
            console.log $state
            $state.go 'login'
        else
          console.log "go login"
          console.log $state
          $state.go "login"
      else
        console.log "Meteor has user"
        console.log $state.is 'login'

        $state.go 'bookings' if $state.is 'login'

    #Accounts.onLogin ->
      #console.group "Login successful ..."
      #if $state.is 'login'
        #if $rootScope.returnToState
          #console.log "redirecting to #{$rootScope.returnToState}"
          #$state.go $rootScope.returnToStateParams
        #else
          #console.log "redirecting to bookings"
          #$state.go('bookings').then (ok)->

            #console.log "ok"
          #.catch (err)->
            #console.error "err"

      #console.groupEnd()

    #Accounts.onLoginFailure ->
      #console.error "Login failed"
      #$state.go 'login'

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

