# [TTT2] RoleVote
RoleVote is an addon for [TTT2](https://github.com/TTT-2/TTT2) that lets the players vote after a map change which of the roles they want to activate/deactivate.
## Convars
```
- ttt_rolevote_autostart     Enable/Disable autostart after map change
- ttt_rolevote_min_players   Sets the minimum players that have to be online for RoleVote being active
                             (Default: 7)
- ttt_rolevote_voteban       0: The players vote the roles that get activated
                             1: The players vote the roles that get banned (Default)
- ttt_rolevote_count         Sets how many roles will be banned/activated (Default: 1)
- ttt_rolevote_role_cooldown Sets how many times a role can't be voted on after it has won a vote
                             (Default: 1)
- ttt_rolevote_always_active Always activated roles (separated by "," i.e.: ttt_rolevote_always_active wrath,jester,beacon)
```
## Admin Commands
```
- ulx rv_start               Starts a vote
- ulx rv_end                 Ends the current vote
- ulx rv_cancel              Cancels the current vote (without banning/activating a role)
```
## Concommands
```
- rolevote_version           Shows the current version of RoleVote
- printRoles                 Prints out all installed roles and shows if they are activated
                             and which roles won the last vote
```
