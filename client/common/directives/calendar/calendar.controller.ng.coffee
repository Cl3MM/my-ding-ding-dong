Bookings = @Bookings

moment.fn.toJSON = ->
  #o = this.toObject()
  o = {}
  #o.ids = @owners?.map (_o)-> _o.id
  o.adding = @adding
  o.booked = @booked
  o.canBook = @canBook
  o.isNew = @isNew
  o.original = @original
  o.owners = @owners
  o.unscoped = @unscoped
  o.myPrecious = @myPrecious
  o

class Calendar
  constructor: ($scope, $reactive, $meteor, @$q, @Notification)->
    $reactive(@).attach $scope

    console.group "Calendar Controller"

    @ownerId = Meteor.user()?._id
    @weeks = []
    @_weeks = []
    @selections = []
    @removables = []
    @cancelations = []
    @bookings = []

    @subscribe 'users'
    @subscribe 'bookings'

    @date = moment.utc().startOf('d')
    @helpers(
      date : moment.utc().startOf('d')
      owners: -> Meteor.users.find {}
      reservations: =>
        start = moment.utc(@date).startOf('month').add(-1,'w')
        end = moment.utc(@date).endOf('month').add(1,'w')
        Bookings.find {
          date: {
            $lte: end.toDate()
            $gte:start.toDate()
          }
        }, {
          fields: {'_id':1, date: 1, color: 1, owner: 1}
        }
    )
    @autorun( =>
      if @reservations[0]
        @display()
        $scope.$apply()
    )
    #Meteor.call 'booking_on', moment(), (err, res)=>
      #return console.error err if err
      #console.group "BOOKING ON"
      #console.log res
      #console.groupEnd()

    labels = moment.weekdays()
    dim = labels.shift()
    labels.push dim
    @days = (lodash.capitalize(s) for s in labels)
    @editing = true
    @range = null
    @selection =
      selecting:
        month: false
        year: false
      isAdding : false
      activeDay : null
      range: []
    console.log @
    console.groupEnd()

  selecta: (what)->
    return (moment.utc(@date).startOf('d').year(i) for i in [moment.utc().year()-2..moment.utc().year()+4] ) if what is 'y'
    return (moment.utc(@date).startOf('year').add(i, 'M') for i in [0..11]) if what is 'm'

  selectMonth: (bool)->
    @selection.selecting.month = bool ? !@selection.selecting.month

  selectYear: (bool)->
    @selection.selecting.year = bool ? !@selection.selecting.year

  month: ->
    f = lodash.memoize (date)->
      lodash.capitalize date.format "MMMM"
    , (d)-> d.valueOf()
    f(@date)

  year: ->
    f = lodash.memoize (date)->
      lodash.capitalize date.format "YYYY"
    , (d)-> d.valueOf()
    f(@date)

  findResaOn: (day)->
    Bookings.find {
        date: day.toDate()
      }, {
        fields: {'_id':1, date: 1, color: 1, owner: 1}
      }
  hazBooking: (day)->
    return [] if @reservations.length is 0
    @findResaOn(day)
    .map (r)=>
      { owner: lodash.find(@owners, (u)-> u._id is r.owner), id: r._id }

  cancelEdition: ->
    @editing = false
    @_weeks.forEach (d)->
      d.booked = false

  toggleEdition: ->
    @editing = !@editing

  nextMonth: ->
    @date = moment.utc(@date).add 1, 'month'
    @display()

  prevMonth: ->
    @date = moment.utc(@date).add -1, 'month'
    @display()

  display: ->
    @weeks = []
    dates = [
      moment.utc(@date).startOf('month').startOf 'week'
      moment.utc(@date).endOf('month').endOf 'week'
    ]
    @range = moment.range(dates)
    weeks = []

    @range.by 'days', (day)=>
      obj = angular.copy day
      obj.unscoped = !day.isSame @date, 'month'
      obj.owners = @hazBooking day
      @initDay obj
      obj.booked = lodash.any( @bookings, (b)-> b.format('DDMMYY') is day.format('DDMMYY') )
      weeks.push obj
    @_weeks = weeks
    @weeks = lodash.chunk @_weeks, 7
    console.log @weeks

  startAdd: (day)->
    @_weeks.forEach (w)->
      w.adding = false
    @selection.isAdding = true
    day.adding = true
    day.isEnd = true
    @selection.activeDay = day

  stopAdd: ->
    return unless @selection.isAdding
    @selection =
      isAdding : false
      activeDay : null

    #_bookings = angular.copy @bookings
    @bookings = @_weeks.reduce (ar, w)=>
      if w.adding
        w.adding = false
        w.booked = !w.booked if w.canBook
      ar.push(w) if w.booked isnt w.original and w.canBook and
        !w.myPrecious #and !lodash.includes @bookings, (b)-> b.format('DD-MM-YY') is w.format('DD-MM-YY')
      w.isEnd = false
      ar
    , []

    #len = @_weeks.length
    #_bookings.forEach (b)=>
      #if @_weeks[0].isAfter b
        #@bookings.shift b
      #else if @_weeks[len-1].isBefore b
        #@bookings.push b

    #if @bookings[0]
      #@bookings = [].concat @bookings, _bookings
    #else @bookings = _bookings

    @cancelations = @_weeks.reduce (ar, w)=>
      ar.push w if w.booked isnt w.original and w.myPrecious
      ar
    , []

    @selections = @populateSelected @bookings
    @removables = @populateSelected @cancelations

  # Populate selections
  populateSelected: (from)->
    to = []
    return to unless from[0]
    selection =
      from: from[0]
      to: from[0]
      diff: 0

    for i in [0..from.length-1]
      if i+1 is from.length
        to.push selection
        return to

      next = from[i+1]
      # if diff between last and next is 1
      # # no gap, last = next
      if selection.to.diff(next, 'days')is -1
        selection.to = angular.copy next
        selection.diff = selection.to.diff selection.from, 'days'
        continue
      # else, there is a one day gap
      # we add the current selection
      to.push selection
      # reset selection for next round
      selection =
        from: angular.copy next
        to: angular.copy next
        diff: 0
    return to

  adding: (day)->
    return unless @selection.isAdding
    min = moment.utc(if @selection.activeDay.isBefore day then @selection.activeDay else day)
    max = moment.utc(if @selection.activeDay.isAfter day then @selection.activeDay else day)
    range = moment.range min, max
    @_weeks.forEach (d)->
      d.adding = d.within(range)
      d.isEnd = false
    @selection.activeDay.isEnd = true
    day.isEnd = true

  confirmSelection: ->
    @bookings.forEach (b)=>
      return unless b.canBook
      return if b.booked is b.original
      owner = lodash.find(@owners, (user)=> user._id is @ownerId )
      Bookings.insert {
        date: b.toDate()
        owner: @ownerId
        #'_id': b.id
      }, (err, data)=>
        if err
          console.error err
          @Notification.error "Une erreur est survenue lors de l'ajout"
          return

        b.id = data[0]._id
        b.owners = [] unless b.owners
        b.owners.push {owner: owner, id: b.id }
        @initDay b
        @updateDay b
        @Notification.success "Réservations ajoutées !"

    @cancelations.forEach (c)=>
      id = _.find(c.owners, (o)=> o.owner._id is @ownerId)?.id
      return unless id
      Bookings.remove id, (err, data)=>
        if err
          console.error err
          @Notification.error "Une erreur est survenue lors de la suppression"
          return

        lodash.remove c.owners, (o)-> o.id is id
        @initDay c
        @updateDay c
        @Notification.success "Réservations supprimées !"
    @bookings = []
    @cancelations = []
    @selections = []
    @removables = []
    @editing = false

  initDay: (day)->
    day.original = false
    day.booked = false
    day.adding = false
    day.isNew = day.owners.length is 0
    day.myPrecious = lodash.any day.owners, (o)=> o.owner._id is @ownerId
    day.canBook = day.isNew or day.myPrecious

  updateDay: (day)=>
    old = lodash.find @_weeks, (w)-> day.format("DDMMYY") is w.format("DDMMYY")
    old = angular.copy day

angular
  .module 'huezNg.common.directives.calendar'
  .controller 'calendarController', ['$scope', '$reactive', '$meteor', '$q', 'Notification', Calendar]
