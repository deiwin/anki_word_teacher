# Load libraries required by the Evernote OAuth
require 'oauth'
require 'oauth/consumer'
  
# Load Thrift & Evernote Ruby libraries
require "evernote_oauth"
require 'evernote-thrift'
   
# Client credentials
OAUTH_CONSUMER_KEY = "<Consumer-Key>"
OAUTH_CONSUMER_SECRET = "<Consumer-Secret>"
  
# Connect to Sandbox server?
SANDBOX = true
