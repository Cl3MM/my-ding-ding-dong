Meteor.startup ->
  if @Bookings.find().count() == 0
    console.log "No bookings, inserting...."
    bookings = [
      {
        date: moment.utc([2015,11,12])
        owner: 1
      }
      {
        date: moment.utc([2015,11,12])
        owner: 2
      }
      {
        date: moment.utc([2015,11,12])
        owner: 3
      }
      {
        date: moment.utc([2015,11,12])
        owner: 4
      }
      {
        date: moment.utc([2015,11,12])
        owner: 5
      }
      {
        date: moment.utc([2015,11,12])
        owner: 6
      }
      {
        date: moment.utc([2015,11,13])
        owner: 1
      }
      {
        date: moment.utc([2015,11,14])
        owner: 1
      }
      {
        date: moment.utc([2015,11,15])
        owner: 1
      }
      {
        date: moment.utc([2015,11,16])
        owner: 1
      }
      {
        date: moment.utc([2015,11,17])
        owner: 1
      }
      {
        date: moment.utc([2015,11,18])
        owner: 1
      }
      {
        date: moment.utc([2015,11,22])
        owner: 1
      }
      {
        date: moment.utc([2015,11,23])
        owner: 1
      }
      {
        date: moment.utc([2015,11,24])
        owner: 1
      }
    ].forEach (b)=>
      console.log "--------"
      console.log b.date
      @Bookings.insert
        date: b.date.toISOString()
        owner: b.owner

  return

