class Bookings
  constructor: ($reactive, $scope, $auth)->
    $reactive(@).attach($scope)
    console.group "Setting up Booking Controller"
    console.log $auth
    @helpers({
      user: -> Meteor.user()
    })
    #console.log @user
    console.groupEnd()
    @bookings = []
    @mode =
      edit: false

  toggleEditMode: ->
    @mode.edit = !@mode.edit


angular
  .module 'huezNg.bookings'
  .controller 'bookingsController', ['$reactive', '$scope', '$auth', Bookings]

