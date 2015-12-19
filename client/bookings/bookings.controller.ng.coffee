class Bookings
  constructor: ($reactive, $scope)->
    $reactive(@).attach($scope)
    console.group "Setting up Booking Controller"
    console.log @user
    console.groupEnd()
    @bookings = []
    @mode =
      edit: false

  toggleEditMode: ->
    @mode.edit = !@mode.edit


angular
  .module 'huezNg.bookings'
  .controller 'bookingsController', ['$reactive', '$scope', Bookings]

