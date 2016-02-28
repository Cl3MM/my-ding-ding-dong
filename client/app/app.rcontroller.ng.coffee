class App
  constructor: ($auth)->
    console.group "Setting up App Controller"
    @user = $auth.currentUser()
    console.log @user
    console.groupEnd()

angular
  .module 'huezNg'
  .controller 'appController', [App]


