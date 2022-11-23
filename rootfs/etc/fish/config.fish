# Put system-wide fish configuration entries here
# or in .fish files in conf.d/
# Files in conf.d can be overridden by the user
# by files with the same name in $XDG_CONFIG_HOME/fish/conf.d

# This file is run by all fish instances.
# To include configuration only for login shells, use
# if status is-login
#    ...
# end
# To include configuration only for interactive shells, use
# if status is-interactive
#   ...
# end

set orange   d65d0e
set brorange fe8019
set bg2      504945
set bg3      665c54
set bg4      7c6f64

set fish_color_autosuggestion     brblack
set fish_color_cancel             -r
set fish_color_command            cyan
set fish_color_comment            brblack
#set fish_color_cwd                cyan
#set fish_color_cwd_root           brred
set fish_color_end                $orange
set fish_color_error              red
set fish_color_escape             $orange
set fish_color_history_current    --bold
#set fish_color_host               normal
set fish_color_match              --background=brblue
set fish_color_normal             normal
set fish_color_operator           red
set fish_color_param              brwhite
set fish_color_quote              brgreen
set fish_color_redirection        bryellow
set fish_color_search_match       --background=$bg2
set fish_color_selection          -r
set fish_color_status             red
#set fish_color_user               brgreen
set fish_color_valid_path         --underline
set fish_pager_color_completion   normal
set fish_pager_color_description  yellow
set fish_pager_color_prefix       --bold --underline
set fish_pager_color_progress     brwhite --background=blue
