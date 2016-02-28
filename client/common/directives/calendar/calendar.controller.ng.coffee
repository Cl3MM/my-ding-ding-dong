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
  #o.owners = @owners
  o.unscoped = @unscoped
  o.myPrecious = @myPrecious
  o.date = this.toISOString()
  o

class Calendar
  constructor: (@$scope, $reactive, $meteor, @$q, @Notification)->
    self = @
    $reactive(@).attach @$scope

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
      date : -> moment.utc().startOf('d')
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
      legend: ->
        o = @getReactively('_weeks').reduce (ar, r)->
          ar = ar.concat r.owners
          ar
        , []
        _.uniq(o.map( (o)-> o.owner ), (o)-> o._id)
    )

    @autorun( =>
      resa = @getReactively 'reservations'
      @display() if resa and Meteor.user()
    )

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
    users = []

    @range.by 'days', (day)=>
      obj = angular.copy day
      obj.unscoped = !day.isSame @date, 'month'
      obj.owners = @hazBooking day
      @initDay obj
      obj.booked = !!lodash.any @bookings, (b)-> b.format('DDMMYY') is day.format('DDMMYY')
      weeks.push obj
    @_weeks = weeks
    @weeks = lodash.chunk @_weeks, 7

  startAdd: (day)->
    @_weeks.forEach (w)->
      w.adding = false
    @selection.isAdding = true
    day.adding = true
    day.isEnd = true
    @selection.activeDay = day

  stopAdd: ->
    return true unless @selection.isAdding
    @selection =
      isAdding : false
      activeDay : null

    len = @_weeks.length
    first = @_weeks[0]
    last = @_weeks[len-1]
    range = moment.range moment.utc(first), moment.utc(last)
    @bookings = @_weeks.reduce (ar, w)=>
      if w.adding
        w.adding = false
        w.booked = !w.booked if w.canBook
      # Push if booked has changed, and canBook and Not our precious
      ar.push(w) if w.booked isnt w.original and w.canBook and
        !w.myPrecious
      w.isEnd = false
      ar
    , @bookings.filter( (b)-> !b.within range  ) #We keep booking not in current calendar (@_weeks)

    @cancelations = @_weeks.reduce (ar, w)=>
      ar.push w if w.booked isnt w.original and w.myPrecious
      ar
    , @cancelations.filter( (b)-> !b.within range  ) #We keep cancelations not in current calendar (@_weeks)

    @selections = @populateSelected @bookings
    @removables = @populateSelected @cancelations

  # Populate selections
  populateSelected: (from)->
    to = []
    return to unless from[0]
    from = lodash.sortBy from, (d)-> d.valueOf()
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
    return true unless @selection.isAdding
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
        #@Notification.success "Réservations ajoutées !"

    @cancelations.forEach (c)=>
      id = _.find(c.owners, (o)=> o.owner._id is @ownerId)?.id
      return unless id
      Bookings.remove id, (err, data)=>
        if err
          console.error err
          @Notification.error "Une erreur est survenue lors de la suppression"
          return

        lodash.remove c.owners, (o)-> o.id is id
        @initDay c, {canceled : false}
        @updateDay c
        #@Notification.success "Réservations supprimées !"
    @bookings = []
    @cancelations = []
    @selections = []
    @removables = []
    @editing = false

  initDay: (day, opts)->
    canceled = lodash.any @cancelations, (b)-> b.format('DDMMYY') is day.format('DDMMYY')
    day.canceled = opts?.canceled ? canceled ? false
      #day.adding = true
      #day.isEnd = false
    #else
      #day.adding = false
    day.adding = false
    day.original = false
    day.booked = false
    day.isNew = day.owners.length is 0
    day.myPrecious = lodash.any day.owners, (o)=> o.owner._id is @ownerId
    day.canBook = day.isNew or day.myPrecious

  updateDay: (day)=>
    old = lodash.find @_weeks, (w)-> day.format("DDMMYY") is w.format("DDMMYY")
    old = angular.copy day
    @$scope.$apply()

angular
  .module 'huezNg.common.directives.calendar'
  .controller 'calendarController', ['$scope', '$reactive', '$meteor', '$q', 'Notification', Calendar]
