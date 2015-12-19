Accounts.onCreateUser (options, user)->
  user.profile = options.profile if options.profile
  user.color = options.color if options.color
  user

#Meteor.methods
  #all_users: ->
    #Meteor.users.find({}, {fields: {'_id':1, emails: 1, color: 1} }).fetch()

Meteor.publish "users", ->
  Meteor.users.find {}, {fields: {emails: 1, profile: 1, id: 1, color: 1}}
