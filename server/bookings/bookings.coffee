Bookings = @Bookings
Meteor.publish 'bookings', ->
  Bookings.find({})

Meteor.publish 'next_bookings', ->
  date = moment.utc().startOf('day').toISOSString()
  Bookings.find({$gte: date: date}, {sort: {date: -1}, limit: 10})


Meteor.methods
  bookings_on: (day)->
    date = moment.utc(day).startOf('day').toDate()
    Bookings.find({
      $eq: {
        date: date
      }
    }, {
      fields: {'_id':1, date: 1, color: 1, owner: 1}
    }).fetch()
