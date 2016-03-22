"use strict"

chai = require 'chai'
sinon = require 'sinon'

chrono = require('chrono-node')

Helper = require('hubot-test-helper')
moment = require 'moment'
momentFormat = 'ddd MMM D YYYY [at] HH:mm'
momentFormatNoTime ='ddd MMM D YYYY'

util = require 'util'


chai.use require 'sinon-chai'
# require('../src/hubot-status-board')(@robot)
helper = new Helper('../src/hubot-status-board.coffee')

expect = chai.expect
chai.use(require('chai-things'))


describe 'hubot-status-board out of office variants', ->
#  statusTypes = ["out of office", "on vacation", "working from home", "working remotely", "sick", "on business travel", "on an errand"]
  statusTypes = ["out of office"]
  beforeEach ->
    @room = helper.createRoom()

  afterEach ->
    @room.destroy()

  for status in statusTypes

    do (status) ->
# failing on whole days
#      dateTypes = ["monday - friday", "from wednesday till monday at 10","10/10/16 - 10/20/16", "tomorrow"]
      dateTypes = ["tomorrow at 12"]

      for dateType in dateTypes
        do (dateType) ->

          context "Jason goes #{status} #{dateType}", ->
            actionDate = chrono.parse(dateType, chrono.parseDate("today at 23:59:59"))
            console.log("Action Date: #{util.inspect(actionDate, { depth: null })}")
            startDate = moment(actionDate[0].start.date() ).format(momentFormat)

            console.log "Implied state = #{util.inspect(actionDate[0].start.impliedValues.hour)}"

            if actionDate.length is 2
              endDate = moment(actionDate[1].start.date() ).format(momentFormat)
            else if actionDate[0].end?
              endDate = moment(actionDate[0].end.date() ).format(momentFormat)

            console.log("Start Date #{startDate}")
            console.log("End Date #{endDate}")

            untilClause = ""
            untilClause = " until #{endDate}" if endDate?
            beforeEach ->
              @room.user.say 'Jason', "hubot I'm #{status} #{dateType}"

            it "responds that @Jason is #{status} from #{startDate} until #{endDate}", ->
              console.log("We got: #{@room.messages}")
              expect(@room.messages).to.include.something.eql ['hubot', "@Jason #{status} from #{startDate}#{untilClause}"]
      #Basic Test

      context "Jason goes #{status}", ->
        beforeEach ->
          @room.user.say 'Jason', "hubot I'm #{status}"

        it "responds that @Jason is #{status}", ->
          console.log("We got: #{@room.messages}")

          expect(@room.messages).to.include.something.eql ['hubot', "@Jason #{status}"]

#describe 'hubot-status-board where are people', ->
#  beforeEach ->
#    @room = helper.createRoom()
#    @room.robot.brain.data.users = [
#      {
#        name: "Boba"
#        real_name: "Boba Fett"
#      }
#      {
#        name: "Darth"
#        real_name: "Darth Vader"
#      }
#
#    ]
#    @room.user.say 'Darth', "hubot I'm running an errand"
#    @room.user.say 'Boba', "hubot I'm on vacation 10/10/16 - 10/20/16"
#
#  afterEach ->
#    @room.destroy()
#
#  context "Jason asks where is boba?", ->
#    beforeEach ->
#      @room.user.say 'Jason',"hubot where is @Boba?"
#
#    it "Should respond that Boba is on on vacation Mon Oct 10 2016 at 12:00 until Thu Oct 20 2016 at 12:0", ->
#      console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
#      expect(@room.messages).to.include.something.eql ['hubot', "@Jason Boba Fett is on vacation from Mon Oct 10 2016 at 12:00 until Thu Oct 20 2016 at 12:00"]
#  context "Jason asks where is everyone?", ->
#    beforeEach ->
#      @room.user.say 'Jason',"hubot where is everyone?"
#      @room.user.say 'Darth', "hubot I'm back"
#      @room.user.say 'Boba', "hubot I am back"
#
#    it "Should respond that Everyone is in", ->
#      console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
#      expect(@room.messages).to.include.something.eql ['hubot', "Everyone's in"]
#
#  context "Jason asks where is darth?", ->
#    beforeEach ->
#      @room.user.say 'Jason',"hubot where is @Darth?"
#
#    it "Should respond that Darth is running an errand", ->
#      console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
#      expect(@room.messages).to.include.something.eql ['hubot', "@Jason Darth Vader is on an errand"]
#
#    context "Jason asks where is @dave?", ->
#      beforeEach ->
#        @room.user.say 'Jason',"hubot where is @Dave?"
#
#      it "Should respond who is Dave?", ->
#        console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
#        expect(@room.messages).to.include.something.eql ['hubot', "@Jason Who is @Dave?"]
#
#  context "Jason asks where is everyone?", ->
#    beforeEach ->
#      @room.user.say 'Jason',"hubot where is everyone?"
#
#    it "Should respond that Everyone is in except for:\nBoba is on vacation\nDarth is running an errand", ->
#      console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
#      expect(@room.messages).to.include.something.eql ['hubot', "Boba Fett is on vacation from Mon Oct 10 2016 at 12:00 until Thu Oct 20 2016 at 12:00\n,Darth Vader is on an errand\n"]



#describe 'hubot-status-board test reset options', ->
#  beforeEach ->
#    @room = helper.createRoom()
#    @room.robot.brain.data.users = [
#      {
#        name: "Boba"
#        real_name: "Boba Fett"
#      }
#      {
#        name: "Darth"
#        real_name: "Darth Vader"
#      }
#
#    ]
#    @room.user.say 'Darth', "hubot I'm running an errand"
#    @room.user.say 'Boba', "hubot I'm on vacation 10/10/16 - 10/20/16"
#
#  afterEach ->
#    @room.destroy()
#
#  context 'Jason performs a HARDRESET', ->
#    beforeEach ->
#      @room.user.say 'Jason', 'hubot HARDRESET'
#      @room.user.say 'Jason', 'hubot where\'s everybody'
#
#    it 'Should Force Reset and mark everybody is in!', ->
#      console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
#      expect(@room.messages).to.include.something.eql ['hubot', "Forced Reset Done, everybody's in!"]
#
#  context 'Jason performs a reset', ->
#    beforeEach ->
#      @room.user.say 'Jason', 'hubot reset'
#      @room.user.say 'Jason', 'hubot where\'s everybody'
#
#    it 'Should respond Nightly Reset Done, Everyone in except for boba out!', ->
#      console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
#      expect(@room.messages).to.include.something.eql ['hubot', "It\'s a new day!  The team is in except for:\nBoba Fett is on vacation from Mon Oct 10 2016 at 12:00 until Thu Oct 20 2016 at 12:00\n"]
#
#  context 'Jason performs a reset after boba comes back', ->
#    beforeEach ->
#      @room.user.say 'Boba', "hubot I am back"
#      @room.user.say 'Jason', 'hubot reset'
#      @room.user.say 'Jason', 'hubot where\'s everybody'
#
#    it 'Should respond Nightly Reset Done, everyone\'s in!', ->
#      console.log("We got: #{util.inspect(@room.messages, { depth: null })}")
#      expect(@room.messages).to.include.something.eql ['hubot', 'It\'s a new day!\nThe entire team is in!']
