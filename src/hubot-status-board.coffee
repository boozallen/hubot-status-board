# Description
#   A hubot script that tracks the status of people.  Who's in, who's out with from and until.  Original concept based on hubot-out-of-office.
#
# Configuration:
#   LIST_OF_ENV_VARS_TO_SET
#
# Commands:
# hubot I am out of the office 
# hubot I am on vacation
# hubot I am remote
# hubot I am on an errand 
# hubot I am on travel
# hubot I am sick
#
# Notes:
#
# Author:
#   jasonnic@gmail.com <nichols_jason@bah.com>

chrono = require 'chrono-node'
moment = require 'moment'
util = require 'util'
# Set moment to be Fri Mar 18 2016 12:00:00
momentFormat = 'ddd MMM D YYYY [at] HH:mm'


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
    robot.logger.debug("Username: #{res.message.user.name.toLowerCase()}" )
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
    
    fromClause = createFromClause userStatus.startDate
    untilClause = createUntilClause userStatus.endDate
    res.reply "#{user.real_name} is #{userStatus.status}#{fromClause}#{untilClause}"


  robot.respond /where(\'s| is) every(one|body)\??/i, (res) ->
    robot.logger.debug("Brain Status: #{util.inspect(robot.brain, {depth:null})}")

    staffOutOfOffice = []
    for own key, user of robot.brain.data.users
      userStatus = robot.brain.get("#{user.name.toLowerCase()}.userStatus")
      robot.logger.debug("UserStatus: #{util.inspect(userStatus)}")

      if userStatus?
        fromClause = createFromClause userStatus.startDate
        untilClause = createUntilClause userStatus.endDate
        staffOutOfOffice.push "#{user.real_name} is #{userStatus.status}#{fromClause}#{untilClause}\n"
        
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
    robot.logger.debug("Brain Status: #{util.inspect(robot.brain, {depth:null})}")

    for own key, user of robot.brain.data.users
        userStatus = robot.brain.get("#{user.name.toLowerCase()}.userStatus")
        
        if userStatus?
            robot.logger.debug("user is #{util.inspect(user, {depth:null})}")
            robot.logger.debug("UserStatus: #{util.inspect(userStatus)}")
            if userStatus.startDate?
                latestDate = userStatus.startDate if userStatus.startDate?
                latestDate = userStatus.endDate if userStatus.endDate?
                robot.logger.debug("latestDate: #{util.inspect(latestDate)}")

                if latestDate? && moment(latestDate).isAfter(chrono.parseDate("today"))
                    robot.logger.debug("Status Until: #{latestDate} not removing status")    
                    fromClause = createFromClause userStatus.startDate
                    untilClause = createUntilClause userStatus.endDate
                    staffOutOfOffice.push "#{user.real_name} is #{userStatus.status}#{fromClause}#{untilClause}\n"
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
    
        


setUntilDate = (robot, res, statusMessage) ->
    
    robot.logger.debug("Match: #{res.match[1]}")
    user = res.message.user.name.toLowerCase()
    userStatus = {status: statusMessage}
    
        
    if res.match[1] is null or res.match[1] is "" or res.match[1] is undefined
        # robot.logger.debug("Brain Full: #{util.inspect(robot.brain)}");
        brain = robot.brain.userForName(user)
        robot.brain.set("#{user}.userStatus", userStatus)
        
        robot.logger.debug("Brain Status: #{util.inspect(robot.brain, { depth: null })}");
        return res.reply(statusMessage)
   
    else
        activityDates = chrono.parse(res.match[1])
        robot.logger.debug("Activity Dates: #{util.inspect(activityDates, { depth: null })}")
        # if moment(statusEndTime).isBefore(chrono.parseDate("today"))
        #     robot.logger.debug('Date before today, setting to next date') 
        #     statusEndTime = chrono.parseDate("next #{res.match[1]}")
        #     robot.logger.debug("new endTime = #{statusEndTime}")  
        # robot.brain.set("#{user}.ooo.until", statusEndTime)
        
        #A little trickery here ... if a time is used on the same day there's only one 
        #parsed result so check to see if there's more than one in activityDates
        userStatus.startDate = activityDates[0].start.date() 
        
        # robot.logger.debug("ACTIVITY DATES SIZE #{activityDates.length}")
        if activityDates.length is 2
            userStatus.endDate = activityDates[1].start.date() 
        else
            userStatus.endDate = activityDates[0].end.date() 
        
        
        robot.brain.set("#{user}.userStatus", userStatus)

        return res.reply "#{userStatus.status}#{createFromClause userStatus.startDate}#{createUntilClause userStatus.endDate}"

createFromClause = (startDate) ->
    if startDate?
        return " from #{moment(startDate).format(momentFormat)}"
    else
    #Don't want Undef
        return ""

createUntilClause = (endDate) ->
    if endDate?
        return " until #{moment(endDate).format(momentFormat)}" 
    else
        #Don't want Undef
        return ""
