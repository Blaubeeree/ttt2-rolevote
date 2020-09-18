# [TTT2] RoleVote
RoleVote is an addon for [TTT2](https://github.com/TTT-2/TTT2) that lets the players vote after a map change which of the roles they want to activate/deactivate.<br>
This addon is still in beta, if you find bugs or have ideas that I can improve tell me them [here](https://github.com/Blaubeeree/ttt2-rolevote/issues).
## Convars
```
- ttt_rolevote_autostart     Enable/Disable autostart after map change
- rolevote_min_players       Sets the minimum players that have to be online for RoleVote being active
                             (Default: 7)
- rolevote_voteban           0: The players vote the roles that get activated
                             1: The players vote the roles that get banned (Default)
- rolevote_count             Sets how many roles will be banned/activated (Default: 1)
- rolevote_role_cooldown     Sets how many times a role can't be voted on after it has won a vote
                             (Default: 1)
- ttt_rolevote_always_active Always activated roles (separated by ",")
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
