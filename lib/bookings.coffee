@Bookings = new Mongo.Collection "bookings"

@Bookings.allow
  insert: (userId, booking)->
    userId and booking.owner is userId
  update: (userId, booking, fields, modifier)->
    userId and booking.owner is userId
  remove: (userId, booking)->
    userId and booking.owner is userId

