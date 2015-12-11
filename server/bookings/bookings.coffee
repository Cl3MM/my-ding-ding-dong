Meteor.publish 'bookings', =>
  @Bookings.find({})
