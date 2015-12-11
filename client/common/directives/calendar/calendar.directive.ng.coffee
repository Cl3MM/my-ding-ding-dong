class Calendar
  constructor: ->
    console.log "Building directive"
    return {
      restrict: 'E'
      scope : {
        #bookings: '='
        editing: '='
      }
      templateUrl: "client/common/directives/calendar/views/calendar.html"
      controller: 'calendarController'
      controllerAs: 'cal'
      bindToController: true
    }

angular
  .module 'huezNg.common.directives.calendar'
  .directive 'calendar', [Calendar]
