if Meteor.isClient
  angular
    .module 'huezNg', [
      'angular-meteor'
      'accounts.ui'
      'ui.router'
      'huezNg.common'
      'huezNg.bookings'
    ]

