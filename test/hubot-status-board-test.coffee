"use strict"

chai = require 'chai'
sinon = require 'sinon'

chrono = require('chrono-node')

Helper = require('hubot-test-helper')
moment = require 'moment'
momentFormat = 'ddd[,] MMM D[,] YYYY [at] HH:mm'
momentFormatNoTime ='ddd[,] MMM D[,] YYYY'

util = require 'util'


chai.use require 'sinon-chai'
# require('../src/hubot-status-board')(@robot)
helper = new Helper('../src/hubot-status-board.coffee')

expect = chai.expect
chai.use(require('chai-things'))


describe 'hubot-status-board out of office variants', ->
  statusTypes = ["out of office", "on vacation", "working from home", "working remotely", "sick", "on business travel", "on an errand"]
  beforeEach ->
    @room = helper.createRoom()

  afterEach ->
    @room.destroy()

  for status in statusTypes

    do (status) ->
      dateTypes = ["monday - friday", "from wednesday till monday at 10","10/10/16 - 10/20/16", "tomorrow", "tomorrow at 10", "tommorrow at 10 till friday at 12", "until tomorrow at 10"]

      for dateType in dateTypes
        do (dateType) ->

          context "Jason goes #{status} #{dateType}", ->
            activityDates = chrono.parse(dateType)
            #console.log("Action Date: #{util.inspect(activityDates, { depth: null })}")

            if activityDates[0].start.impliedValues.hour > 0
              startDate = moment(activityDates[0].start.date() ).format(momentFormatNoTime)
            else
              startDate = moment(activityDates[0].start.date() ).format(momentFormat)


            #console.log "Implied state = #{util.inspect(activityDates[0].start.impliedValues.hour)}"

            if activityDates.length is 2
              if activityDates[1].start.impliedValues.hour > 0
                endDate = moment(activityDates[1].start.date() ).format(momentFormatNoTime)
              else
                endDate = moment(activityDates[1].start.date() ).format(momentFormat)
            else if activityDates[0].end?
              if activityDates[0].end.impliedValues.hour > 0
                endDate = moment(activityDates[0].end.date() ).format(momentFormatNoTime)
              else
                endDate = moment(activityDates[0].end.date() ).format(momentFormat)


            #console.log("Start Date #{startDate}")
            #console.log("End Date #{endDate}")

            if endDate?
              untilClause = " until #{endDate}"
              functionWord=" from "
            else
              untilClause = ""
              functionWord=" on "

            beforeEach ->
              @room.user.say 'Jason', "hubot I'm #{status} #{dateType}"

            it "responds that @Jason is #{status}#{functionWord}#{startDate}#{untilClause}", ->
              #console.log("We got: #{@room.messages}")
              expect(@room.messages).to.include.something.eql ['hubot', "@Jason is #{status}#{functionWord}#{startDate}#{untilClause}"]
#Basic Test

      context "Jason goes #{status}", ->
        beforeEach ->
          @room.user.say 'Jason', "hubot I'm #{status}"

        it "responds that @Jason is #{status}", ->
          #console.log("We got: #{@room.messages}")

          expect(@room.messages).to.include.something.eql ['hubot', "@Jason #{status}"]

describe 'hubot-status-board where are people', ->
  beforeEach ->
    @room = helper.createRoom()
    @room.robot.brain.data.users = [
      {
        name: "Boba"
        real_name: "Boba Fett"
      }
      {
        name: "Darth"
        real_name: "Darth Vader"
      }

    ]
    @room.user.say 'Darth', "hubot I'm running an errand"
    @room.user.say 'Boba', "hubot I'm on vacation 10/10/16 - 10/20/16"

  afterEach ->
    @room.destroy()

  context "Jason asks where is boba?", ->
    beforeEach ->
      @room.user.say 'Jason',"hubot where is @Boba?"

    it "Should respond that Boba is on on vacation Mon Oct 10 2016 till Thu Oct 20 2016", ->
      #console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
      expect(@room.messages).to.include.something.eql ['hubot', "@Jason Boba Fett is on vacation from Mon, Oct 10, 2016 until Thu, Oct 20, 2016"]
  context "Jason asks where is everyone?", ->
    beforeEach ->
      @room.user.say 'Jason',"hubot where is everyone?"
      @room.user.say 'Darth', "hubot I'm back"
      @room.user.say 'Boba', "hubot I am back"

    it "Should respond that Everyone is in", ->
      #console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
      expect(@room.messages).to.include.something.eql ['hubot', "Everyone's in"]

  context "Jason asks where is darth?", ->
    beforeEach ->
      @room.user.say 'Jason',"hubot where is @Darth?"

    it "Should respond that Darth is running an errand", ->
      #console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
      expect(@room.messages).to.include.something.eql ['hubot', "@Jason Darth Vader is on an errand today"]

    context "Jason asks where is @dave?", ->
      beforeEach ->
        @room.user.say 'Jason',"hubot where is @Dave?"

      it "Should respond who is Dave?", ->
        #console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
        expect(@room.messages).to.include.something.eql ['hubot', "@Jason Who is @Dave?"]

  context "Jason asks where is everyone?", ->
    beforeEach ->
      @room.user.say 'Jason',"hubot where is everyone?"

    it "Should respond that Everyone is in except for:\nBoba is on vacation\nDarth is running an errand", ->
      #console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
      expect(@room.messages).to.include.something.eql ['hubot', "\nBoba Fett is on vacation from Mon, Oct 10, 2016 until Thu, Oct 20, 2016,\nDarth Vader is on an errand today"]



describe 'hubot-status-board test reset options', ->
  beforeEach ->
    @room = helper.createRoom()
    @room.robot.brain.data.users = [
      {
        name: "Boba"
        real_name: "Boba Fett"
      }
      {
        name: "Darth"
        real_name: "Darth Vader"
      }
      {
        name: "Siracha"
        real_name:"Siracha"
      }

    ]
    @room.user.say 'Darth', "hubot I'm running an errand"
    @room.user.say 'Boba', "hubot I'm on vacation 10/10/16 - 10/20/16"


  afterEach ->
    @room.destroy()

  context 'Jason performs a HARDRESET', ->
    beforeEach ->
      @room.user.say 'Jason', 'hubot HARDRESET'
      @room.user.say 'Jason', 'hubot where\'s everybody'

    it 'Should Force Reset and mark everybody is in!', ->
      console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
      expect(@room.messages).to.include.something.eql ['hubot', "Forced Reset Done, everybody's in!"]

  context 'Jason performs a reset', ->
    beforeEach ->
      @room.user.say 'Jason', 'hubot reset'
      @room.user.say 'Jason', 'hubot where\'s everybody'

    it 'Should respond Nightly Reset Done, Everyone in except for boba out!', ->
      console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
      expect(@room.messages).to.include.something.eql ['hubot', "It\'s a new day!  The team is in except for:\nBoba Fett is on vacation from Mon, Oct 10, 2016 until Thu, Oct 20, 2016"]

  context 'Jason performs a reset testing concept of today', ->
    beforeEach ->
      @room.user.say 'Siracha', "hubot I'm ooo today"
      @room.user.say 'Jason', 'hubot reset'
      @room.user.say 'Jason', 'hubot where\'s everybody'

    it 'Should respond Nightly Reset Done, Everyone in except for boba out and siracha out!', ->
      console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
      expect(@room.messages).to.include.something.eql ['hubot', "It\'s a new day!  The team is in except for:\nBoba Fett is on vacation from Mon, Oct 10, 2016 until Thu, Oct 20, 2016,\nSiracha is out of office on Thu, Mar 24, 2016"]

  context 'Jason performs a reset after boba comes back', ->
    beforeEach ->
      @room.user.say 'Boba', "hubot I am back"
      @room.user.say 'Jason', 'hubot reset'
      @room.user.say 'Jason', 'hubot where\'s everybody'

    it 'Should respond Nightly Reset Done, everyone\'s in!', ->
      console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
      expect(@room.messages).to.include.something.eql ['hubot', 'It\'s a new day!\nThe entire team is in!']
