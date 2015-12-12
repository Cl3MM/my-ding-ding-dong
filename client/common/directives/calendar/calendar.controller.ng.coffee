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
  constructor: ($scope, $reactive, $meteor, @Notification)->
    $reactive(@).attach $scope

    console.group "Calendar Controller"

    @ownerId = Meteor.user()?._id ? 2
    @date = moment.utc().startOf('d')
    @weeks = []
    @_weeks = []
    @selections = []
    @removables = []
    @cancelations = []
    @owners = {}
    for i in [1..6]
      @owners["#{i}"] = randomColor()

    @bookings = []
    #@helpers(
      #reservations = ->
        #Bookings.find {}
    #)
    #@reservations = @helpers.reservations()

    @reservations = []
    Meteor.subscribe 'bookings',
      onReady: (subscription)=>
        @reservations = $meteor.collection Bookings
        @display()

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

  hazBooking: (day)->
    return [] if @reservations.length is 0
    f = lodash.memoize (d)=>
      return @reservations.filter (r)->
        moment.utc(r.date).format('DDMMYY') is d.format('DDMMYY')
      .map (r)=>
        { color: @owners["#{r.owner}"], owner: r.owner, id: r._id }
    , (d)-> d.valueOf()
    f(day)

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
    today = angular.copy @date
    dates = [
      moment.utc(today).startOf('month').startOf 'week'
      moment.utc(today).endOf('month').endOf 'week'
    ]
    @range = moment.range(dates)
    weeks = []

    @range.by 'days', (day)=>
      obj = angular.copy day
      obj.unscoped = !day.isSame today, 'month'
      obj.owners = @hazBooking day
      @initDay obj
      obj.booked = lodash.any( @bookings, (b)-> b.format('DDMMYY') is day.format('DDMMYY') )
      console.log obj if obj.booked
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

    @bookings = @_weeks.reduce (ar, w)=>
      if w.adding
        w.adding = false
        w.booked = !w.booked if w.canBook
      ar.push(w) if w.booked isnt w.original and w.canBook and !w.myPrecious
      w.isEnd = false
      ar
    , []

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
      @reservations.save( {
        date: b.toISOString()
        owner: @ownerId
        #'_id': b.id
      }).then (data)=>
        b.id = data[0]._id
        b.owners.push {owner: @ownerId, color: @owners[@ownerId], id: b.id }
        @initDay b
        @updateDay b
      .catch (err)=>
        console.error err
        @Notification.error "Une erreur est survenue"
    @cancelations.forEach (c)=>
      id = _.find(c.owners, (o)=> o.owner is @ownerId)?.id
      return unless id
      @reservations.remove(id).then (data)=>
        lodash.remove c.owners, (o)-> o.id is id
        @initDay c
        @updateDay c
      .catch (err)->
        console.error err
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
    day.myPrecious = lodash.any day.owners, (o)=> o.owner is @ownerId
    day.canBook = day.isNew or day.myPrecious

  updateDay: (day)=>
    old = lodash.find @_weeks, (w)-> day.format("DDMMYY") is w.format("DDMMYY")
    console.group "Update #{day}"
    console.log "old: #{old}"
    console.log angular.copy old
    console.log angular.copy day
    console.groupEnd()
    old = angular.copy day

angular
  .module 'huezNg.common.directives.calendar'
  .controller 'calendarController', ['$scope', '$reactive', '$meteor', 'Notification', Calendar]
