# [TTT2] RoleVote

RoleVote is an addon for [TTT2](https://github.com/TTT-2/TTT2) that lets the players vote after a map change which of the roles they want to activate/deactivate.

## Server Convars

| Convar                     | Default | Description                                                                                          |
| -------------------------- | :-----: | ---------------------------------------------------------------------------------------------------- |
| ttt_rolevote_autostart     |    1    | Enable/Disable autostart after map change                                                            |
| ttt_rolevote_voteban       |    1    | 0: The players vote the roles that get activated <br> 1: The players vote the roles that get banned  |
| ttt_rolevote_none_option   |    1    | Enable/Disable the 'No Role' option                                                                  |
| ttt_rolevote_min_players   |    7    | Sets the minimum players that have to be online for RoleVote being active                            |
| ttt_rolevote_count         |    1    | Sets how many roles will be banned/activated                                                         |
| ttt_rolevote_role_cooldown |    1    | Sets how many times a role can't be voted on after it has won a vote                                 |
| ttt_rolevote_always_active |         | Always activated roles (separated by ",") <br> i.e. `ttt_rolevote_always_active wrath,jester,beacon` |

## Client Convars

| Convar               | Default | Description        |
| -------------------- | :-----: | ------------------ |
| ttt_rolevote_old_gui |    0    | Enable the old GUI |

## Admin Commands

| Command       | Description                                                  |
| ------------- | ------------------------------------------------------------ |
| ulx rv_start  | Starts a vote                                                |
| ulx rv_end    | Ends the current vote                                        |
| ulx rv_cancel | Cancels the current vote (without banning/activating a role) |

## Console Commands

| Command          | Description                                                                                      |
| ---------------- | ------------------------------------------------------------------------------------------------ |
| rolevote_version | Shows the current version of RoleVote                                                            |
| printRoles       | Prints out all installed roles and shows if they are activated and which roles won the last vote |
