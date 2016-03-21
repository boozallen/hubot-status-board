"use strict"

chai = require 'chai'
sinon = require 'sinon'

chrono = require('chrono-node')

Helper = require('hubot-test-helper')
moment = require 'moment'
momentFormat = 'ddd MMM D YYYY [at] HH:mm'
util = require 'util'


chai.use require 'sinon-chai'
# require('../src/hubot-status-board')(@robot)
helper = new Helper('../src/hubot-status-board.coffee')

expect = chai.expect
chai.use(require('chai-things'))


describe 'hubot-status-board out of office variants', ->
  statusTypes = ["out of office", "on holiday", "working from home", "working remotely", "sick", "on business travel", "on an errand"]
#   statusTypes = ["out of office"]
  beforeEach ->
    @room = helper.createRoom()

  afterEach ->
    @room.destroy()
    
  for status in statusTypes
    do (status) ->
        context "Jason goes #{status} from wednesday till monday at 10", ->
            actionDate = chrono.parse("wednesday till monday at 10") 
            console.log("Action Date: #{util.inspect(actionDate)}")
            startDate = moment(actionDate[0].start.date() ).format(momentFormat)
            endDate = moment(actionDate[1].start.date() ).format(momentFormat)
            console.log("Start Date #{startDate}")
            console.log("End Date #{endDate}")
        
            beforeEach ->
                @room.user.say 'Jason', "hubot I'm #{status} from wednesday till monday at 10"
                
            it "responds that @Jason is #{status} from #{startDate} until #{endDate}", ->
                console.log("We got: #{@room.messages}")
                expect(@room.messages).to.include.something.eql ['hubot', "@Jason #{status} from #{startDate} until #{endDate}"]   

        context "jason goes #{status} tomorrow 10 - 12", ->
            actionDate = chrono.parse("tomorrow 10 - 12")
            console.log("Action Date: #{actionDate}")
            startDate = moment(actionDate[0].start.date()).format(momentFormat)
            endDate = moment(actionDate[0].end.date() ).format(momentFormat)
            
            beforeEach ->
                @room.user.say 'Jason', "hubot I'm #{status} from tomorrow 10 - 12"
                
            it "responds that @Jason is #{status} from #{startDate} until #{endDate}", ->
                console.log("We got: #{@room.messages}")

                expect(@room.messages).to.include.something.eql ['hubot', "@Jason #{status} from #{startDate} until #{endDate}"]   
        
        context "Jason goes #{status}", ->
            beforeEach ->
                @room.user.say 'Jason', "hubot I'm #{status}"
                
            it "responds that @Jason is #{status}", ->
                console.log("We got: #{@room.messages}")

                expect(@room.messages).to.include.something.eql ['hubot', "@Jason #{status}"]   

