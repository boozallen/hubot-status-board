# Description
#   A hubot script that tracks the status of people.  Who's in, who's out with from and until.  Original concept based on hubot-out-of-office.
#
# Configuration:
#   LIST_OF_ENV_VARS_TO_SET
#
# Commands:
# hubot I am out of the office <optional natural language based date>
# hubot I am on vacation <optional natural language based date>
# hubot I am remote <optional natural language based date>
# hubot I am on an errand <optional natural language based date>
# hubot I am on travel <optional natural language based date>
# hubot I am sick <optional natural language based date>
# hubot I am back - tell hubot you are back
# hubot Where is everybody? - ask hubot where everybody is
# hubot Where is @user1? - ask hubot where user1 is
# hubot it's a new day|reset - resets everyone's status to in for a fresh day of fun
# hubot HARDRESET - forces reset for all users
#
# Notes:
# Status can be modified with natural language based dates
#  Sample Dates
#    "monday - friday"
#    "from wednesday till monday at 10"
#    "10/10/16 - 10/20/16"
#    "tomorrow"
#    "tomorrow at 10"
#    "tommorrow at 10 till friday at 12"

# Parsing set to interpret dates such that monday - friday might not take next monday if today after Monday.
# I've left this behavior in place.
# Doesn't quite recognize that until tomorrow at 10 means that I'm out from now till tomorrow at 10
# Next week causes crash

#
# Author:
#   jasonnic@gmail.com <nichols_jason@bah.com>

chrono = require 'chrono-node'
moment = require 'moment'
util = require 'util'
# Set moment to be Fri Mar 18 2016 12:00:00
momentFormat = 'ddd[,] MMM D[,] YYYY [at] HH:mm'
momentFormatNoTime = 'ddd[,] MMM D[,] YYYY'


module.exports = (robot) ->
  robot.respond /I(?:\'m| am) (?:ooo|out of (?:the )?office)(.*$)?/i, (res) ->
    setUntilDate robot, res, "out of office"

  robot.respond /I(?:\'m| am) on (?:holiday|vacation)(.*$)?/i, (res) ->
    setUntilDate robot, res, "on vacation"

  robot.respond /I(?:\'m| am) (?:wfh|working from home)(.*$)?/i, (res) ->
    setUntilDate robot, res, "working from home"

  robot.respond /I(?:\'m| am) (?:remote|working remote(?:ly))(.*$)?/i, (res) ->
    setUntilDate robot, res, "working remotely"

  robot.respond /I(?:\'m| am) sick(.*$)?/i, (res) ->
    setUntilDate robot, res, "sick"


  robot.respond /I(?:\'m| am) (?:ot|traveling|on travel|on business travel)(.*$)?/i, (res) ->
    setUntilDate robot, res, "on business travel"


  robot.respond /I(?:\'m| am)(?: running| on) an (?:errand)(.*$)?/i, (res) ->
    setUntilDate robot, res, "on an errand"

  robot.respond /I(\'m| am) back/i, (res) ->
    robot.logger.debug("Username: #{res.message.user.name.toLowerCase()}")
    robot.brain.remove("#{res.message.user.name.toLowerCase()}.userStatus")
    robot.logger.debug("Brain Status: #{util.inspect(robot.brain, {depth: null})}")

    res.reply "welcome back!"

  robot.respond /where(?:\'s| is) @([\w.-]*)\??/i, (res) ->
    robot.logger.debug("Matches: #{util.inspect(res.match)}")
    username = res.match[1]
    user = robot.brain.userForName username
    return res.reply "Who is @#{username}?" unless user?

    robot.logger.debug("Brain Status: #{util.inspect(robot.brain, {depth: null})}")

    userStatus = robot.brain.get("#{username.toLowerCase()}.userStatus")
    robot.logger.debug("UserStatus: #{util.inspect(userStatus)}")

    return res.reply "#{user.real_name} is in" unless userStatus.status?
    res.reply "#{user.real_name} is #{userStatus.status}#{createTemporalClause(userStatus)}"

  robot.respond /where(\'s| is) every(one|body)\??/i, (res) ->
    robot.logger.debug("Brain Status: #{util.inspect(robot.brain, {depth: null})}")

    staffOutOfOffice = []
    for own key, user of robot.brain.data.users
      userStatus = robot.brain.get("#{user.name.toLowerCase()}.userStatus")
      robot.logger.debug("UserStatus: #{util.inspect(userStatus)}")

      if userStatus?
        staffOutOfOffice.push "\n\t#{user.real_name} is #{userStatus.status}#{createTemporalClause(userStatus)}"

    robot.logger.debug("staffOutOfOffice: #{util.inspect(staffOutOfOffice)}")
    # response = results.reduce(((x,y) ->
    #     robot.logger.debug("Y: #{util.inspect(y)}")
    #     fromClause = createFromClause y.userStatus.startDate
    #     untilClause = createUntilClause y.userStatus.endDate
    #     robot.logger.debug("From: #{fromClause}")
    #     robot.logger.debug("To: #{untilClause}")
    #     x + "#{y.name} is #{y.status}#{fromClause}#{untilClause}\n"), "")
    # robot.logger.debug("Response: #{util.inspect(response)}")
    return res.send 'Everyone\'s in' unless staffOutOfOffice.length > 0
    res.send "#{staffOutOfOffice}"

  ##Nightly reset
  robot.respond /(it(\'s| is) a new day|reset|reset|nightly)/i, (res) ->
    staffOutOfOffice = []
    robot.logger.debug("Brain Status: #{util.inspect(robot.brain, {depth: null})}")

    for own key, user of robot.brain.data.users
      userStatus = robot.brain.get("#{user.name.toLowerCase()}.userStatus")

      if userStatus?
        robot.logger.debug("user is #{util.inspect(user, {depth: null})}")
        robot.logger.debug("UserStatus: #{util.inspect(userStatus)}")
        if userStatus.startDate?
          latestDate = userStatus.startDate if userStatus.startDate?
          latestDate = userStatus.endDate if userStatus.endDate?
          robot.logger.debug("latestDate: #{util.inspect(latestDate)}")

          if latestDate? && moment(latestDate).isAfter(chrono.parseDate("today"))
            robot.logger.debug("Status Until: #{latestDate} not removing status")
            staffOutOfOffice.push "#{user.real_name} is #{userStatus.status}#{createTemporalClause userStatus}\n"
          else
            robot.brain.remove("#{user.name.toLowerCase()}.userStatus")
        else
          robot.brain.remove("#{user.name.toLowerCase()}.userStatus")

    robot.logger.debug("staffOutOfOffice: #{util.inspect(staffOutOfOffice)}")

    if staffOutOfOffice.length > 0
      return res.send "It's a new day!  The team is in except for:\n#{staffOutOfOffice}"
    else
      return res.send 'It\'s a new day!\nThe entire team is in!'

  robot.respond /HARDRESET/, (res) ->
    for own key, user of robot.brain.data.users
      robot.brain.remove("#{user.name.toLowerCase()}.userStatus")
    robot.logger.debug("Brain Status: #{util.inspect(robot.brain)}")
    return res.send 'Forced Reset Done, everybody\'s in!'


#Implied date seems to only show up with values at the hr if a user doesn't specify a time.  Since we
#want the date to not end at 12pm we can
#* add clause to date
#* modify chrono code
#* keep the 12pm but display the full date (using this option)
setUntilDate = (robot, res, statusMessage) ->
  robot.logger.debug("Match: #{res.match[1]}")
  user = res.message.user.name.toLowerCase()
  userStatus = {status: statusMessage}

  #Basically a status without a time frame (i.e. today).  This status will be reset nightly
  if res.match[1] is null or res.match[1] is "" or res.match[1] is undefined
    robot.brain.set("#{user}.userStatus", userStatus)
    return res.reply(statusMessage)

  else
    activityDates = chrono.parse(res.match[1], new Date())
    robot.logger.debug("Activity Dates: #{util.inspect(activityDates, {depth: null})}")
    #         if moment(statusEndTime).isBefore(chrono.parseDate("today"))
    #             robot.logger.debug('Date before today, setting to next date')
    #             statusEndTime = chrono.parseDate("next #{res.match[1]}")
    #             robot.logger.debug("new endTime = #{statusEndTime}")
    #         robot.brain.set("#{user}.ooo.until", statusEndTime)

    #A little trickery here ... if a time is used on the same day there's only one
    #parsed result so check to see if there's more than one in activityDates

    #If Implied date has an hour assume it's an all day activity
    if activityDates[0].start.impliedValues.hour > 0
      userStatus.allDayActivityOnStartDate = true
    userStatus.startDate = activityDates[0].start.date()

    robot.logger.debug("Userstatus: #{util.inspect(userStatus)}")

    if activityDates.length is 2
      if activityDates[1].start.impliedValues.hour > 0
        userStatus.allDayActivityOnEndDate = true
      userStatus.endDate = activityDates[1].start.date()
    else if activityDates[0].end?
      if activityDates[0].end.impliedValues.hour > 0
        userStatus.allDayActivityOnEndDate = true
      userStatus.endDate = activityDates[0].end.date()

    robot.brain.set("#{user}.userStatus", userStatus)

    return res.reply "is #{userStatus.status}#{createTemporalClause userStatus}"

createTemporalClause = (userStatus) ->
  returnStatement = ""
  if userStatus.endDate?
    functionWord = " from "
  else
    functionWord = " on "

  if userStatus.startDate?
#Simplify date (no time if this is an an all day event)
    if userStatus.allDayActivityOnStartDate
      returnStatement = "#{functionWord}#{moment(userStatus.startDate).format(momentFormatNoTime)}"
    else
      returnStatement = "#{functionWord}#{moment(userStatus.startDate).format(momentFormat)}"
  else
#Coming in without a date
    return " today"

  if userStatus.endDate?
    if userStatus.allDayActivityOnEndDate
      returnStatement += " until #{moment(userStatus.endDate).format(momentFormatNoTime)}"
    else
      returnStatement += " until #{moment(userStatus.endDate).format(momentFormat)}"
  return returnStatement
