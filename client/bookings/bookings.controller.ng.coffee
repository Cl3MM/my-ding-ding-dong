class Bookings
  constructor: ->
    @bookings = []
    @mode =
      edit: false

  toggleEditMode: ->
    @mode.edit = !@mode.edit


angular
  .module 'huezNg.bookings'
  .controller 'bookingsController', [Bookings]

