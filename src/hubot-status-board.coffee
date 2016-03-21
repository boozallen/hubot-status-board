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
    setUntilDate robot, res, "on holiday" 


  robot.respond /I(?:\'m| am) (?:wfh|working from home)(.*$)?/i, (res) ->
    setUntilDate robot, res, "working from home"
  
  robot.respond /I(?:\'m| am) (?:remote|working remote(?:ly))(.*$)?/i, (res) ->
    setUntilDate robot, res, "working remotely"

  robot.respond /I(?:\'m| am) sick(.*$)?/i, (res) ->
    setUntilDate robot, res, "sick"

   
  robot.respond /I(?:\'m| am) (?:ot|traveling|on travel|on business travel)(.*$)?/i, (res) ->
    setUntilDate robot, res, "on business travel" 
    
     
  robot.respond /I(?:\'m| am) on an (?:errand)(.*$)?/i, (res) ->
    setUntilDate robot, res, "on an errand" 
    
      
  robot.respond /I(\'m| am) back/i, (res) ->
    robot.brain.remove("#{res.message.user.name}.userStatus")
    res.reply "welcome back!"



  robot.respond /where(\'s| is) @([\w.-]*)\??/i, (res) ->
    username = res.match[2]
    user = robot.brain.userForName username
    return res.reply "who is #{username}?" unless user?

    status = robot.brain.get("#{username.toLowerCase()}.userStatus")

    return res.reply "#{user.real_name} should be in..." unless status?
    res.reply "#{user.real_name} is #{status}"

  robot.respond /where(\'s| is) every(one|body)\??/i, (res) ->
    results = []
    for own key, user of robot.brain.data.users
      status = robot.brain.get("#{user.name.toLowerCase()}.userStatus")
      if status?
        robot.logger.debug("Status: #{status}")
        untilDate = robot.brain.get("#{user.name.toLowerCase()}.userStatus.until")
        if untilDate?
            #robot.logger.debug("status until #{untilDate}") if untilDate?
            results.push {name: user.real_name, status: status, until: moment(untilDate).format(momentFormat)}
        else
            results.push {name: user.real_name, status: status}
    robot.logger.debug("Results: #{util.inspect(results)}")    
    response = results.reduce(((x,y) -> 
        if y.until?
            x + "#{y.name} is #{y.status} until #{y.until}\n"
        else
            x + "#{y.name} is #{y.status}\n"), "")
    robot.logger.debug("Response: #{util.inspect(response)}")
    return res.send 'everybody should be in...' unless !!response
    res.send "#{response}" 

  ##Nightly reset
  robot.respond /(it(\'s| is) a new day|reset|reset status|nightly)/i, (res) ->
    results = []
    for own key, user of robot.brain.data.users
        untilDate = robot.brain.get("#{user.name.toLowerCase()}.ooo.until")

        if untilDate? && moment(untilDate).isAfter(chrono.parseDate("today"))
            robot.logger.debug("Status Until: #{untilDate} not removing status")    

            results.push {name: user.real_name, status: robot.brain.get("#{user.name.toLowerCase()}.ooo"), until: moment(untilDate).format(momentFormat)}
        else
            robot.brain.remove("#{user.name.toLowerCase()}.ooo")
    if results?
        robot.logger.debug("Results: #{util.inspect(results)}")    

        response = results.reduce(((x,y) -> x + "#{y.name} is #{y.status} until #{y.until}\n"), "") 
        robot.logger.debug("Response: #{util.inspect(response)}")

        return res.send "It's a new day!  The team is in except for:\n#{response}"
    else
        return res.send 'It\'s a new day!\nThe entire team is in!'
    
   robot.respond /HARDRESET/, (res) ->
    for own key, user of robot.brain.data.users
      robot.brain.remove("#{user.name.toLowerCase()}.userStatus")
    robot.logger.debug("Brain Status: #{util.inspect(robot.brain)}")
    return res.send 'Forced Reset Done, everybody is in!'
    
        


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
        # robot.logger.debug("Brain Status: #{util.inspect(robot.brain, { depth: null })}");
        #{moment(chrono.parseDate('12/31/16')).format(momentFormat)}
        fromClause = " from #{moment(userStatus.startDate).format(momentFormat)}" if userStatus.startDate
        untilClause =  " until #{moment(userStatus.endDate).format(momentFormat)}" if userStatus.endDate
        return res.reply "#{userStatus.status}#{fromClause}#{untilClause}"

