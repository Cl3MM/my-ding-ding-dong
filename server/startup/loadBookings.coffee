Meteor.startup ->

  #users = Meteor.users.find()
  #users.forEach (u)->
    #Meteor.users.remove u._id

  if Meteor.users.find().count() is 0
    users = [
      { username: 'a' }
      { username: 'b' }
      { username: 'c' }
      { username: 'd' }
      { username: 'e' }
    ]
    console.log "---------"
    users.forEach (u)->
      console.log "inserting user #{u.username}"
      Accounts.createUser
        username: u.username
        color: randomColor()
        email: "#{u.username}@#{u.username}.com",
        password: ("#{u.username}" for i in [0..5]).join('')
        confirmed: lodash.random(10) <= 5
    console.log "---------"

  if @Bookings.find().count() is 0
    console.log "No bookings, inserting...."
    users = Meteor.users.find()
    uids =   users.map (u)-> u._id
    cache = {}
    bookings = [1,2,3,4,5,6,7,8,9,12,12,12,12,13,14,15,16,18,18,19,20,21,21,23,25,26].map (d)->
      id = null
      unless "#{d}" of cache
        id = lodash.sample uids
        cache["#{d}"] = [id]
      else
        v = cache["#{d}"]
        x = uids.reduce (ar,i)->
          ar[+(if ~ar[1].indexOf(i) then 1 else 0)].push i
          ar
        , [[],v]
        id = lodash.sample x[0]
        cache["#{d}"].push id
      return {
        date: moment.utc([2015,11,d])
        owner: id
        color: lodash.find(users, (u)-> u._id is id)?.color ? randomColor()
      }
    .forEach (b)=>
      @Bookings.insert
        date: b.date.toDate()
        owner: b.owner
        color: b.color

  return

