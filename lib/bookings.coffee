@Bookings = new Mongo.Collection "bookings"

@Bookings.allow
  insert: ->
    true
  update: ->
    true
  remove: ->
    true
