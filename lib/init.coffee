#if Meteor.isServer
  #Accounts._options.forbidClientAccountCreation = false

if Meteor.isClient
  accountsUIBootstrap3.setLanguage 'fr'
  #Accounts.config
    #forbidClientAccountCreation: false
#AccountsTemplates.configure
  #forbidClientAccountCreation: false

