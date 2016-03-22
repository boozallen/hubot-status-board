# hubot-status-board

A hubot script that tracks the status of people.  Who's in, who's out with from and until.  Original concept based on hubot-out-of-office.

See [`src/hubot-status-board.coffee`](src/hubot-status-board.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-hubot-status-board --save`

Then add **hubot-hubot-status-board** to your `external-scripts.json`:

```json
[
  "hubot-hubot-status-board"
]
```

## Sample Interaction

###Accepts Dates per the Chrono-Node Project
* "monday - friday"
* "from wednesday till monday at 10"
* "10/10/16 - 10/20/16"
* "tomorrow"
* "tomorrow at 10"
* "tommorrow at 10 till friday at 12"

###Status of: 
* hubot I am out of the office
* hubot I am on vacation
* hubot I am remote
* hubot I am on an errand
* hubot I am on travel
* hubot I am sick

```
darth>> hubot I'm running an errand'
hubot>> @Darth on an errand

Boba>>  hubot I'm on vacation 10/10/16 - 10/20/16
hubot>>  @Boba is on vacation from Mon, Oct 10, 2016 until Thu, Oct 20, 2016

user1>>  hubot HARDRESET
hubot>>  Forced Reset Done, everybody's in!

user1>>  hubot where's everybody'
hubot>>  Boba Fett is on vacation from Mon, Oct 10, 2016 until Thu, Oct 20, 2016
Darth Vader is on an errand today,
  
user1>> hubot reset
hubot>> It's a new day!  The team is in except for:
Boba Fett is on vacation from Mon, Oct 10, 2016 until Thu, Oct 20, 2016 

user1>> hubot where's everybody
hubot>> Boba Fett is on vacation from Mon, Oct 10, 2016 until Thu, Oct 20, 2016

Boba>> hubot I am back
hubot>> @Boba welcome back!'

user1>> hubot reset
hubot>> It's a new day!
The entire team is in!'
        
```
