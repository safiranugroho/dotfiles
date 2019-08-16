#!/usr/bin/env zsh

emulate -L zsh
setopt noaliases

() {
setopt extended_glob no_prompt_{bang,subst} prompt_{cr,percent,sp}
local LC_ALL=C.UTF-8

typeset -g __p9k_root_dir
typeset -gi force=0

local opt
while getopts 'd:f' opt; do
  case $opt in
    d)  __p9k_root_dir=$OPTARG;;
    f)  force=1;;
    +f) force=0;;
    '?') return 1;;
  esac
done

if (( OPTIND <= ARGC )); then
  print -lr -- "wizard.zsh: invalid arguments: $@" >&2
  return 1
fi

: ${__p9k_root_dir:=${0:h:h:A}}

typeset -gr __p9k_root_dir
typeset -gri force

source $__p9k_root_dir/internal/configure.zsh || return

typeset -ri prompt_indent=2

typeset -ra bg_color=(240 238 236 234)
typeset -ra frame_color=(244 242 240 238)
typeset -ra sep_color=(248 246 244 242)
typeset -ra prefix_color=(250 248 246 244)

typeset -r left_triangle='\uE0B2'
typeset -r right_triangle='\uE0B0'
typeset -r left_angle='\uE0B3'
typeset -r right_angle='\uE0B1'
typeset -r down_triangle='\uE0BC'
typeset -r up_triangle='\uE0BA'
typeset -r fade_in='░▒▓'
typeset -r fade_out='▓▒░'
typeset -r vertical_bar='|'
typeset -r slanted_bar='\uE0BD'

typeset -ra lean_left=(
  '' '${extra_icons[1]:+$extra_icons[1] }%31F$extra_icons[2]%B%39F~%b%31F/%B%39Fpowerlevel10k%b%f $prefixes[1]%76F$extra_icons[3]master ⇡2%f '
  '' '%76F❯%f █'
)

typeset -ra lean_right=(
  ' $prefixes[2]%134F⎈ minikube%f' ''
  '' ''
)

typeset -ra classic_left=(
  '%$frame_color[$color]F╭─' '%F{$bg_color[$color]}$left_tail%K{$bg_color[$color]} ${extra_icons[1]:+$extra_icons[1]%K{$bg_color[$color]\} %$sep_color[$color]F$left_subsep%f }%31F$extra_icons[2]%B%39F~%b%K{$bg_color[$color]}%31F/%B%39Fpowerlevel10k%b%K{$bg_color[$color]} %$sep_color[$color]F$left_subsep%f %$prefix_color[$color]F$prefixes[1]%76F$extra_icons[3]master ⇡2 %k%$bg_color[$color]F$left_head%f'
  '%$frame_color[$color]F╰─' '%f █'
)

typeset -ra classic_right=(
  '%$bg_color[$color]F$right_head%K{$bg_color[$color]}%f %$prefix_color[$color]F$prefixes[2]%134Fminikube ⎈ %k%F{$bg_color[$color]}$right_tail%f' '%$frame_color[$color]F─╮%f'
  '' '%$frame_color[$color]F─╯%f'
)

function prompt_length() {
  local COLUMNS=1024
  local -i x y=$#1 m
  if (( y )); then
    while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
      x=y
      (( y *= 2 ));
    done
    local xy
    while (( y > x + 1 )); do
      m=$(( x + (y - x) / 2 ))
      typeset ${${(%):-$1%$m(l.x.y)}[-1]}=$m
    done
  fi
  print $x
}

function print_prompt() {
  local left=${style}_left
  local right=${style}_right
  left=("${(@P)left}")
  right=("${(@P)right}")
  eval "left=(${(@)left:/(#b)(*)/\"$match[1]\"})"
  eval "right=(${(@)right:/(#b)(*)/\"$match[1]\"})"
  if (( num_lines == 1)); then
    left=($left[2] $left[4])
    right=($right[1] $right[3])
  else
    (( left_frame )) || left=('' $left[2] '' '%76F❯%f █')
    (( right_frame )) || right=($right[1] '' '' '')
  fi
  local -i right_indent=prompt_indent
  local -i width=$(prompt_length ${(g::):-$left[1]$left[2]$right[1]$right[2]})
  while (( __p9k_wizard_columns - width <= prompt_indent + right_indent )); do
    (( --right_indent ))
  done
  local -i i
  for ((i = 1; i < $#left; i+=2)); do
    local l=${(g::):-$left[i]$left[i+1]}
    local r=${(g::):-$right[i]$right[i+1]}
    local -i gap=$((__p9k_wizard_columns - prompt_indent - right_indent - $(prompt_length $l$r)))
    (( num_lines == 2 && i == 1 )) && local fill=$gap_char || local fill=' '
    print -n  -- ${(pl:$prompt_indent:: :)}
    print -nP -- $l
    print -nP -- "%$frame_color[$color]F${(pl:$gap::$fill:)}%f"
    print -P  -- $r
  done
}

function href() {
  print -r -- $'%{\e]8;;'${1//\%/%%}$'\a%}'${1//\%/%%}$'%{\e]8;;\a%}'
}

function centered() {
  local n=$(prompt_length ${(g::)1})
  print -n -- ${(pl:$(((__p9k_wizard_columns - n) / 2)):: :)}
  print -P -- $1
}

function clear() {
  if (( $+commands[clear] )); then
    command clear
  elif zmodload zsh/termcap 2>/dev/null; then
    echotc cl
  else
    print -n -- "\e[H\e[J"
  fi
}

function quit() {
  clear
  if (( force )); then
    print -P "Powerlevel10k configuration wizard has been aborted. To run it again, type:"
    print -P ""
    print -P "  %2Fp10k%f %Bconfigure%b"
    print -P ""
  else
    print -P "Powerlevel10k configuration wizard has been aborted. It will run again"
    print -P "next time unless you define at least one Powerlevel10k configuration option."
    print -P "To define an option that does nothing except for disabling Powerlevel10k"
    print -P "configuration wizard, type the following command:"
    print -P ""
    print -P "  %2Fecho%f %3F'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true'%f >>! $__p9k_zshrc_u"
    print -P ""
    print -P "To run Powerlevel10k configuration wizard right now, type:"
    print -P ""
    print -P "  %2Fp10k%f %Bconfigure%b"
    print -P ""
  fi
  exit 1
}

function ask_diamond() {
  while true; do
    clear
    if (( force )); then
      print -P "This is %4FPowerlevel10k configuration wizard%f. It will ask you a few"
      print -P "questions and configure your prompt."
    else
      print -P "This is %4FPowerlevel10k configuration wizard%f. You are seeing it because"
      print -P "you haven't defined any Powerlevel10k configuration options. It will"
      print -P "ask you a few questions and configure your prompt."
    fi
    print -P ""
    centered "%BDoes this look like a %b%2Fdiamond%f%B (square rotated 45 degrees)?%b"
    centered "reference: $(href https://graphemica.com/%E2%97%86)"
    print -P ""
    centered "--->  \uE0B2\uE0B0  <---"
    print -P ""
    print -P "%B(y)  Yes.%b"
    print -P ""
    print -P "%B(n)  No.%b"
    print -P ""
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [ynq]: %b"} || quit
    case $key in
      q) quit;;
      y) cap_diamond=1; break;;
      n) cap_diamond=0; break;;
    esac
  done
}

function ask_lock() {
  while true; do
    clear
    [[ -n $2 ]] && centered "$2"
    centered "%BDoes this look like a %b%2Flock%f%B?%b"
    centered "reference: $(href https://fontawesome.com/icons/lock)"
    print -P ""
    centered "--->  $1  <---"
    print -P ""
    print -P "%B(y)  Yes.%b"
    print -P ""
    print -P "%B(n)  No.%b"
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [ynrq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      y) cap_lock=1; break;;
      n) cap_lock=0; break;;
    esac
  done
}

function ask_python() {
  while true; do
    clear
    centered "%BDoes this look like a %b%2FPython logo%f%B?%b"
    centered "reference: $(href https://fontawesome.com/icons/python)"
    print -P ""
    centered "--->  \uE63C  <---"
    print -P ""
    print -P "%B(y)  Yes.%b"
    print -P ""
    print -P "%B(n)  No.%b"
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [ynrq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      y) cap_python=1; break;;
      n) cap_python=0; break;;
    esac
  done
}

function ask_debian() {
  while true; do
    clear
    centered "%BDoes this look like a %b%2FDebian logo%f%B (swirl/spiral)?%b"
    centered "reference: $(href https://www.debian.org/logos/openlogo-nd-100.jpg)"
    print -P ""
    centered "--->  \uF306  <---"
    print -P ""
    print -P "%B(y)  Yes.%b"
    print -P ""
    print -P "%B(n)  No.%b"
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [ynrq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      y) cap_debian=1; break;;
      n) cap_debian=0; break;;
    esac
  done
}

function ask_narrow_icons() {
  if [[ $POWERLEVEL9K_MODE == (powerline|compatible) ]]; then
    cap_narrow_icons=0
    return
  fi
  local text="X"
  text+="%1F${icons[VCS_GIT_ICON]// }%fX"
  text+="%2F${icons[VCS_GIT_GITHUB_ICON]// }%fX"
  text+="%3F${icons[DATE_ICON]// }%fX"
  text+="%4F${icons[TIME_ICON]// }%fX"
  text+="%5F${icons[RUBY_ICON]// }%fX"
  text+="%6F${icons[AWS_EB_ICON]// }%fX"
  while true; do
    clear
    centered "%BDo all these icons %b%2Ffit between the crosses%f%B?%b"
    print -P ""
    centered "--->  $text  <---"
    print -P ""
    print -P "%B(y)  Yes. Icons are very close to the crosses but there is %b%2Fno overlap%f%B.%b"
    print -P ""
    print -P "%B(n)  No. Some icons %b%2Foverlap%f%B neighbouring crosses.%b"
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [ynrq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      y) cap_narrow_icons=1; options+='small icons'; break;;
      n) cap_narrow_icons=0; options+='large icons'; break;;
    esac
  done
}

function ask_style() {
  while true; do
    clear
    centered "%BPrompt Style%b"
    print -P ""
    print -P "%B(1)  Lean.%b"
    print -P ""
    style=lean print_prompt
    print -P ""
    print -P "%B(2)  Classic.%b"
    print -P ""
    style=classic print_prompt
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [12rq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      1) style=lean; options+=lean; break;;
      2) style=classic; options+=classic; break;;
    esac
  done
}

function ask_color() {
  [[ $style != classic ]] && return
  if [[ $LINES -lt 26 ]]; then
    local nl=''
  else
    local nl=$'\n'
  fi
  while true; do
    clear
    centered "%BPrompt Color%b"
    print -n $nl
    print -P "%B(1)  Lightest.%b"
    print -n $nl
    color=1 print_prompt
    print -P ""
    print -P "%B(2)  Light.%b"
    print -n $nl
    color=2 print_prompt
    print -P ""
    print -P "%B(3)  Dark.%b"
    print -n $nl
    color=3 print_prompt
    print -P ""
    print -P "%B(4)  Darkest.%b"
    print -n $nl
    color=4 print_prompt
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [1234rq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      1) color=1; options+=lightest; break;;
      2) color=2; options+=light; break;;
      3) color=3; options+=dark; break;;
      4) color=4; options+=darkest; break;;
    esac
  done
}

function os_icon_name() {
  local uname="$(uname)"
  if [[ $uname == Linux && "$(uname -o 2>/dev/null)" == Android ]]; then
    echo ANDROID_ICON
  else
    case $uname in
      SunOS)                     echo SUNOS_ICON;;
      Darwin)                    echo APPLE_ICON;;
      CYGWIN_NT-* | MSYS_NT-*)   echo WINDOWS_ICON;;
      FreeBSD|OpenBSD|DragonFly) echo FREEBSD_ICON;;
      Linux)
        local os_release_id
        if [[ -r /etc/os-release ]]; then
          local lines=(${(f)"$(</etc/os-release)"})
          lines=(${(@M)lines:#ID=*})
          (( $#lines == 1 )) && os_release_id=${lines[1]#ID=}
        fi
        case $os_release_id in
          *arch*)                  echo LINUX_ARCH_ICON;;
          *debian*)                echo LINUX_DEBIAN_ICON;;
          *raspbian*)              echo LINUX_RASPBIAN_ICON;;
          *ubuntu*)                echo LINUX_UBUNTU_ICON;;
          *elementary*)            echo LINUX_ELEMENTARY_ICON;;
          *fedora*)                echo LINUX_FEDORA_ICON;;
          *coreos*)                echo LINUX_COREOS_ICON;;
          *gentoo*)                echo LINUX_GENTOO_ICON;;
          *mageia*)                echo LINUX_MAGEIA_ICON;;
          *centos*)                echo LINUX_CENTOS_ICON;;
          *opensuse*|*tumbleweed*) echo LINUX_OPENSUSE_ICON;;
          *sabayon*)               echo LINUX_SABAYON_ICON;;
          *slackware*)             echo LINUX_SLACKWARE_ICON;;
          *linuxmint*)             echo LINUX_MINT_ICON;;
          *alpine*)                echo LINUX_ALPINE_ICON;;
          *aosc*)                  echo LINUX_AOSC_ICON;;
          *nixos*)                 echo LINUX_NIXOS_ICON;;
          *devuan*)                echo LINUX_DEVUAN_ICON;;
          *manjaro*)               echo LINUX_MANJARO_ICON;;
          *)                       echo LINUX_ICON;;
        esac
        ;;
    esac
  fi
}

function ask_extra_icons() {
  if [[ $POWERLEVEL9K_MODE == (powerline|compatible) ]]; then
    return
  fi
  local os_icon=${(g::)icons[$(os_icon_name)]}
  local dir_icon=${(g::)icons[HOME_SUB_ICON]}
  local vcs_icon=${(g::)icons[VCS_GIT_GITHUB_ICON]}
  local branch_icon=${(g::)icons[VCS_BRANCH_ICON]}
  if (( cap_narrow_icons )); then
    os_icon=${os_icon// }
    dir_icon=${dir_icon// }
    vcs_icon=${vcs_icon// }
  fi
  branch_icon=${branch_icon// }
  if [[ $style == classic ]]; then
    os_icon="%255F$os_icon%f"
  else
    os_icon="%f$os_icon"
  fi
  os_icon="%B$os_icon%b"
  local many=("$os_icon" "$dir_icon " "$vcs_icon $branch_icon ")
  while true; do
    clear
    centered "%BIcons%b"
    print -P ""
    print -P "%B(1)  Few icons.%b"
    print -P ""
    extra_icons=('' '' '') print_prompt
    print -P ""
    print -P "%B(2)  Many icons.%b"
    print -P ""
    extra_icons=("$many[@]") print_prompt
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [12rq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      1) extra_icons=('' '' ''); options+='few icons'; break;;
      2) extra_icons=("$many[@]"); options+='many icons'; break;;
    esac
  done
}

function ask_prefixes() {
  local fluent=('on ' 'at ')
  while true; do
    clear
    centered "%BPrompt Flow%b"
    print -P ""
    print -P "%B(1)  Concise.%b"
    print -P ""
    prefixes=('' '') print_prompt
    print -P ""
    print -P "%B(2)  Fluent.%b"
    print -P ""
    prefixes=("$fluent[@]") print_prompt
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [12rq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      1) prefixes=('' ''); options+=concise; break;;
      2) prefixes=("$fluent[@]"); options+=fluent; break;;
    esac
  done
}

function ask_separators() {
  if [[ $style != classic || $cap_diamond != 1 ]]; then
    return
  fi
  while true; do
    local extra=
    clear
    centered "%BPrompt Separators%b"
    print -P "                 separator"
    print -P "%B(1)  Angled.%b         |"
    print -P "                     v"
    left_sep=$right_triangle right_sep=$left_triangle left_subsep=$right_angle right_subsep=$left_angle print_prompt
    print -P ""
    print -P "%B(2)  Vertical.%b"
    print -P ""
    left_sep='' right_sep='' left_subsep=$vertical_bar right_subsep=$vertical_bar print_prompt
    print -P ""
    if [[ $POWERLEVEL9K_MODE == nerdfont-complete ]]; then
      extra+=3
      print -P "%B(3)  Slanted.%b"
      print -P ""
      left_sep=$down_triangle right_sep=$up_triangle left_subsep=$slanted_bar right_subsep=$slanted_bar print_prompt
      print -P ""
    fi
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [12${extra}rq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      1)
        left_sep=$right_triangle
        right_sep=$left_triangle
        left_subsep=$right_angle
        right_subsep=$left_angle
        options+='angled separators'
        break
        ;;
      2)
        left_sep=''
        right_sep=''
        left_subsep=$vertical_bar
        right_subsep=$vertical_bar
        options+='vertical separators'
        break
        ;;
      3)
        if [[ $extra == *3* ]]; then
          left_sep=$down_triangle
          right_sep=$up_triangle
          left_subsep=$slanted_bar
          right_subsep=$slanted_bar
          options+='slanted separators'
          break
        fi
        ;;
    esac
  done
}

function ask_heads() {
  if [[ $style != classic || $cap_diamond != 1 ]]; then
    return
  fi
  while true; do
    local extra=
    clear
    centered "%BPrompt Heads%b"
    print -P ""
    print -P "%B(1)  Sharp.%b"
    print -P ""
    left_head=$right_triangle right_head=$left_triangle print_prompt
    print -P ""
    print -P "%B(2)  Blurred.%b"
    print -P ""
    left_head=$fade_out right_head=$fade_in print_prompt
    print -P ""
    if [[ $POWERLEVEL9K_MODE == nerdfont-complete ]]; then
      extra+=3
      print -P "%B(3)  Slanted.%b"
      print -P ""
      left_head=$down_triangle right_head=$up_triangle print_prompt
      print -P ""
    fi
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [12rq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      1) left_head=$right_triangle; right_head=$left_triangle; options+='sharp heads';   break;;
      2) left_head=$fade_out;       right_head=$fade_in;       options+='blurred heads'; break;;
      3)
        if [[ $extra == *3* ]]; then
          left_head=$down_triangle
          right_head=$up_triangle
          options+='slanted heads'
          break
        fi
        ;;
    esac
  done
}

function ask_tails() {
  if [[ $style != classic ]]; then
    return
  fi

  if [[ $POWERLEVEL9K_MODE == nerdfont-complete && $LINES -lt 26 ]]; then
    local nl=''
  else
    local nl=$'\n'
  fi
  while true; do
    local extra=
    clear
    centered "%BPrompt Tails%b"
    print -n $nl
    print -P "%B(1)  Flat.%b"
    print -n $nl
    left_tail='' right_tail='' print_prompt
    print -P ""
    print -P "%B(2)  Blurred.%b"
    print -n $nl
    left_tail=$fade_in right_tail=$fade_out print_prompt
    print -P ""
    if (( cap_diamond )); then
      extra+=3
      print -P "%B(3)  Sharp.%b"
      print -n $nl
      left_tail=$left_triangle right_tail=$right_triangle print_prompt
      print -P ""
      if [[ $POWERLEVEL9K_MODE == nerdfont-complete ]]; then
        extra+=4
        print -P "%B(4)  Slanted.%b"
        print -n $nl
        left_tail=$up_triangle right_tail=$down_triangle print_prompt
        print -P ""
      fi
    fi
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [12${extra}rq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      1) left_tail='';       right_tail='';        options+='flat tails';    break;;
      2) left_tail=$fade_in; right_tail=$fade_out; options+='blurred tails'; break;;
      3)
        if [[ $extra == *3* ]]; then
          left_tail=$left_triangle
          right_tail=$right_triangle
          options+='sharp tails'
          break
        fi
        ;;
      4)
        if [[ $extra == *4* ]]; then
          left_tail=$up_triangle
          right_tail=$down_triangle
          options+='slanted tails'
          break
        fi
        ;;
    esac
  done
}

function ask_num_lines() {
  while true; do
    clear
    centered "%BPrompt Height%b"
    print -P ""
    print -P "%B(1)  One line.%b"
    print -P ""
    num_lines=1 print_prompt
    print -P ""
    print -P "%B(2)  Two lines.%b"
    print -P ""
    num_lines=2 print_prompt
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [12rq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      1) num_lines=1; options+='1 line'; break;;
      2) num_lines=2; options+='2 lines'; break;;
    esac
  done
}

function ask_gap_char() {
  if [[ $num_lines != 2 ]]; then
    return
  fi
  while true; do
    clear
    centered "%BPrompt Connection%b"
    print -P ""
    print -P "%B(1)  Disconnected.%b"
    print -P ""
    gap_char=" " print_prompt
    print -P ""
    print -P "%B(2)  Dotted.%b"
    print -P ""
    gap_char="·" print_prompt
    print -P ""
    print -P "%B(3)  Solid.%b"
    print -P ""
    gap_char="─" print_prompt
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [123rq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      1) gap_char=" "; options+=disconnected; break;;
      2) gap_char="·"; options+=dotted; break;;
      3) gap_char="─"; options+=solid; break;;
    esac
  done
}

function ask_frame() {
  if [[ $style != classic || $num_lines != 2 ]]; then
    return
  fi

  (( LINES >= 26 )) && local nl=$'\n' || local nl=''
  while true; do
    clear
    centered "%BPrompt Frame%b"
    print -n $nl
    print -P "%B(1)  No frame.%b"
    print -n $nl
    left_frame=0 right_frame=0 print_prompt
    print -P ""
    print -P "%B(2)  Left.%b"
    print -n $nl
    left_frame=1 right_frame=0 print_prompt
    print -P ""
    print -P "%B(3)  Right.%b"
    print -n $nl
    left_frame=0 right_frame=1 print_prompt
    print -P ""
    print -P "%B(4)  Full.%b"
    print -n $nl
    left_frame=1 right_frame=1 print_prompt
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [1234rq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      1) left_frame=0; right_frame=0; options+='no frame';    break;;
      2) left_frame=1; right_frame=0; options+='left frame';  break;;
      3) left_frame=0; right_frame=1; options+='right frame'; break;;
      4) left_frame=1; right_frame=1; options+='full frame';  break;;
    esac
  done
}

function ask_empty_line() {
  while true; do
    clear
    centered "%BPrompt Spacing%b"
    print -P ""
    print -P "%B(1)  Compact.%b"
    print -P ""
    print_prompt
    print_prompt
    print -P ""
    print -P "%B(2)  Sparse.%b"
    print -P ""
    print_prompt
    print -P ""
    print_prompt
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [12rq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      1) empty_line=0; options+='compact'; break;;
      2) empty_line=1; options+='sparse';  break;;
    esac
  done
}

function ask_confirm() {
  while true; do
    clear
    centered "%BLooks good?%b"
    print -P ""
    print_prompt
    (( empty_line )) && print -P ""
    print_prompt
    print -P ""
    print -P "%B(y)  Yes.%b"
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [yrq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      y) break;;
    esac
  done
}

function ask_config_overwrite() {
  config_backup=
  if [[ ! -e $__p9k_cfg_path ]]; then
    write_config=1
    return
  fi
  while true; do
    clear
    centered "Powerlevel10k config file already exists."
    centered "%BOverwrite %b%2F${__p9k_cfg_path_u//\\/\\\\}%f%B?%b"
    print -P ""
    print -P "%B(y)  Yes.%b"
    print -P ""
    print -P "(r)  Restart from the beginning."
    print -P "(q)  Quit and do nothing."
    print -P ""

    local key=
    read -k key${(%):-"?%BChoice [yrq]: %b"} || quit
    case $key in
      q) quit;;
      r) return 1;;
      y)
        config_backup="$(mktemp ${TMPDIR:-/tmp}/$__p9k_cfg_basename.XXXXXXXXXX)" || exit 1
        cp $__p9k_cfg_path $config_backup                                        || exit 1
        config_backup_u=${${TMPDIR:+\$TMPDIR}:-/tmp}/${(q-)config_backup:t}
        write_config=1
        break
        ;;
    esac
  done
}

function generate_config() {
  local base && base="$(<$__p9k_root_dir/config/p10k-$style.zsh)" || return
  local lines=("${(@f)base}")

  function sub() {
    lines=("${(@)lines/#(#b)([[:space:]]#)typeset -g POWERLEVEL9K_$1=*/$match[1]typeset -g POWERLEVEL9K_$1=$2}")
  }

  function uncomment() {
    lines=("${(@)lines/#(#b)([[:space:]]#)\# $1(  |)/$match[1]$1$match[2]$match[2]}")
  }

  function rep() {
    lines=("${(@)lines//$1/$2}")
  }

  sub MODE $POWERLEVEL9K_MODE

  if (( cap_narrow_icons )); then
    sub VISUAL_IDENTIFIER_EXPANSION "'\${P9K_VISUAL_IDENTIFIER// }'"
    sub BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION "'\${P9K_VISUAL_IDENTIFIER// }'"
    sub OS_ICON_CONTENT_EXPANSION "'%B\${P9K_CONTENT// }'"
  else
    sub VISUAL_IDENTIFIER_EXPANSION "'\${P9K_VISUAL_IDENTIFIER}'"
    sub BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION "'\${P9K_VISUAL_IDENTIFIER}'"
  fi

  if [[ $POWERLEVEL9K_MODE == compatible ]]; then
    # Many fonts don't have the gear icon.
    sub BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION "'⇶'"
  fi

  if [[ $POWERLEVEL9K_MODE == awesome-fontconfig && $cap_python == 0 ]]; then
    uncomment 'typeset -g POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION'
    uncomment 'typeset -g POWERLEVEL9K_ANACONDA_VISUAL_IDENTIFIER_EXPANSION'
    uncomment 'typeset -g POWERLEVEL9K_PYENV_VISUAL_IDENTIFIER_EXPANSION'
    sub VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION '🐍'
    sub ANACONDA_VISUAL_IDENTIFIER_EXPANSION '🐍'
    sub PYENV_VISUAL_IDENTIFIER_EXPANSION '🐍'
  fi

  if [[ $style == classic ]]; then
    sub BACKGROUND $bg_color[$color]
    sub MULTILINE_FIRST_PROMPT_GAP_FOREGROUND $frame_color[$color]
    sub MULTILINE_FIRST_PROMPT_PREFIX "'%$frame_color[$color]F╭─'"
    sub MULTILINE_NEWLINE_PROMPT_PREFIX "'%$frame_color[$color]F├─'"
    sub MULTILINE_LAST_PROMPT_PREFIX "'%$frame_color[$color]F╰─'"
    sub MULTILINE_FIRST_PROMPT_SUFFIX "'%$frame_color[$color]F─╮'"
    sub MULTILINE_NEWLINE_PROMPT_SUFFIX "'%$frame_color[$color]F─┤'"
    sub MULTILINE_LAST_PROMPT_SUFFIX "'%$frame_color[$color]F─╯'"
    sub LEFT_SUBSEGMENT_SEPARATOR "'%$sep_color[$color]F$left_subsep'"
    sub RIGHT_SUBSEGMENT_SEPARATOR "'%$sep_color[$color]F$right_subsep'"
    sub LEFT_SEGMENT_SEPARATOR "'$left_sep'"
    sub RIGHT_SEGMENT_SEPARATOR "'$right_sep'"
    sub LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL "'$left_tail'"
    sub LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL "'$left_head'"
    sub RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL "'$right_head'"
    sub RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL "'$right_tail'"
    sub VCS_LOADING_FOREGROUND $sep_color[$color]
    rep '%248F' "%$prefix_color[$color]F"
  fi

  if [[ -n ${(j::)extra_icons} ]]; then
    local branch_icon=${icons[VCS_BRANCH_ICON]// }
    sub VCS_BRANCH_ICON "'$branch_icon '"
    uncomment os_icon
  else
    uncomment 'typeset -g POWERLEVEL9K_DIR_CLASSES'
    uncomment 'typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_EXPANSION'
    uncomment 'typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION'
    uncomment 'typeset -g POWERLEVEL9K_TIME_VISUAL_IDENTIFIER_EXPANSION'
    sub VCS_VISUAL_IDENTIFIER_EXPANSION ''
    sub COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION ''
    sub TIME_VISUAL_IDENTIFIER_EXPANSION ''
  fi

  if [[ -n ${(j::)prefixes} ]]; then
    uncomment 'typeset -g POWERLEVEL9K_VCS_PREFIX'
    uncomment 'typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX'
    uncomment 'typeset -g POWERLEVEL9K_CONTEXT_PREFIX'
    uncomment 'typeset -g POWERLEVEL9K_KUBECONTEXT_PREFIX'
    uncomment 'typeset -g POWERLEVEL9K_TIME_PREFIX'
    [[ $style == classic ]] && local fg="%$prefix_color[$color]F" || local fg="%f"
    sub VCS_PREFIX "'${fg}on '"
    sub COMMAND_EXECUTION_TIME_PREFIX "'${fg}took '"
    sub CONTEXT_PREFIX "'${fg}with '"
    sub KUBECONTEXT_PREFIX "'${fg}at '"
    sub TIME_PREFIX "'${fg}at '"
    sub CONTEXT_TEMPLATE "'%n$fg at %180F%m'"
    sub CONTEXT_ROOT_TEMPLATE "'%n$fg at %227F%m'"
  fi

  if (( num_lines == 1 )); then
    local -a tmp
    local line
    for line in "$lines[@]"; do
      [[ $line == ('      newline'|*'===[ Line #'*) ]] || tmp+=$line
    done
    lines=("$tmp[@]")
  fi

  sub MULTILINE_FIRST_PROMPT_GAP_CHAR "'$gap_char'"

  if [[ $style == classic && $num_lines == 2 ]]; then
    if (( ! right_frame )); then
      sub MULTILINE_FIRST_PROMPT_SUFFIX ''
      sub MULTILINE_NEWLINE_PROMPT_SUFFIX ''
      sub MULTILINE_LAST_PROMPT_SUFFIX ''
    fi
    if (( ! left_frame )); then
      sub MULTILINE_FIRST_PROMPT_PREFIX ''
      sub MULTILINE_NEWLINE_PROMPT_PREFIX ''
      sub MULTILINE_LAST_PROMPT_PREFIX ''
      uncomment prompt_char
      sub STATUS_OK false
      sub STATUS_ERROR false
    fi
  fi

  (( empty_line )) && sub PROMPT_ADD_NEWLINE true || sub PROMPT_ADD_NEWLINE false

  local header=${(%):-"# Generated by Powerlevel10k configuration wizard on %D{%Y-%m-%d at %H:%M %Z}."}$'\n'
  header+="# Based on romkatv/powerlevel10k/config/p10k-$style.zsh"
  if [[ $commands[sum] == ('/bin'|'/usr/bin'|'/usr/local/bin')'/sum' ]]; then
    local -a sum
    if sum=($(sum <<<${base//$'\r\n'/$'\n'} 2>/dev/null)) && (( $#sum == 2 )); then
      header+=", checksum $sum[1]"
    fi
  fi
  header+=$'.\n'
  local line="# Wizard options: $options[1]"
  local opt
  for opt in $options[2,-1]; do
    if (( $#line + $#opt > 85 )); then
      header+=$line
      header+=$',\n'
      line="# $opt"
    else
      line+=", $opt"
    fi
  done
  header+=$line
  header+=$'.\n# Type `p10k configure` to generate another config.\n#'

  if [[ -e $__p9k_cfg_path ]]; then
    unlink $__p9k_cfg_path || return 1
  fi
  print -lr -- "$header" "$lines[@]" >$__p9k_cfg_path
}

function write_zshrc() {
  if [[ -e $__p9k_zshrc ]]; then
    local lines=(${(f)"$(<$__p9k_zshrc)"})
    local f1=$__p9k_cfg_path
    local f2=$__p9k_cfg_path_u
    local f3=${__p9k_cfg_path_u/#\~\//\$HOME\/}
    local f4=${__p9k_cfg_path_u/#\~\//\"\$HOME\"\/}
    local f5="'$f1'"
    local f6="\"$f1\""
    local f7="\"$f3\""
    if [[ -n ${(@M)lines:#(#b)[^#]#([^[:IDENT:]]|)source[[:space:]]##($f1|$f2|$f3|$f4|$f5|$f6|$f7)*} ]]; then
      print -rP "No changes have been made to %4F$__p9k_zshrc_u%f because it already sources %2F$__p9k_cfg_path_u%f."
      return
    fi
  fi

  local comments=(
    "# To customize prompt, run \`p10k configure\` or edit $__p9k_cfg_path_u."
  )
  print -lrP -- "" $comments "[[ -f $__p9k_cfg_path_u ]] && source $__p9k_cfg_path_u" >>$__p9k_zshrc

  print -rP ""
  print -rP "The following lines have been appended to %4F$__p9k_zshrc_u%f:"
  print -rP ""
  print -lrP -- '  '${^comments} "  %3F[[%f %B-f $__p9k_cfg_path_u%b %3F]]%f && %2Fsource%f %B$__p9k_cfg_path_u%b"
}

if (( force )); then
  _p9k_can_configure || return
else
  _p9k_can_configure -q || return
fi

source $__p9k_root_dir/internal/icons.zsh || return

while true; do
  local POWERLEVEL9K_MODE= style= config_backup= config_backup_u= gap_char=' '
  local left_subsep= right_subsep= left_tail= right_tail= left_head= right_head=
  local -i num_lines=0 write_config=0 empty_line=0 color=2 left_frame=1 right_frame=1
  local -i cap_diamond=0 cap_python=0 cap_debian=0 cap_narrow_icons=0 cap_lock=0
  local -a extra_icons=('' '' '')
  local -a prefixes=('' '')
  local -a options=()

  ask_diamond || continue
  if [[ -n $AWESOME_GLYPHS_LOADED ]]; then
    POWERLEVEL9K_MODE=awesome-mapped-fontconfig
  else
    ask_lock '\uF023' || continue
    if (( ! cap_lock )); then
      ask_lock '\uE138' "Let's try another one." || continue
      if (( cap_lock )); then
        (( cap_diamond )) && POWERLEVEL9K_MODE=awesome-patched || POWERLEVEL9K_MODE=flat
      else
        (( cap_diamond )) && POWERLEVEL9K_MODE=powerline || POWERLEVEL9K_MODE=compatible
      fi
    elif (( ! cap_diamond )); then
      POWERLEVEL9K_MODE=awesome-fontconfig
    else
      ask_debian || continue
      if (( cap_debian )); then
        POWERLEVEL9K_MODE=nerdfont-complete
      else
        POWERLEVEL9K_MODE=awesome-fontconfig
        ask_python || continue
      fi
    fi
  fi
  if [[ $POWERLEVEL9K_MODE == powerline ]]; then
    options+=powerline
  elif (( cap_diamond )); then
    options+="$POWERLEVEL9K_MODE + powerline"
  else
    options+="$POWERLEVEL9K_MODE"
  fi
  if (( cap_diamond )); then
    left_subsep=$right_angle
    right_subsep=$left_angle
    left_head=$right_triangle
    right_head=$left_triangle
  else
    left_subsep=$vertical_bar
    right_subsep=$vertical_bar
    left_head=$fade_out
    right_head=$fade_in
  fi
  _p9k_init_icons
  ask_narrow_icons     || continue
  ask_style            || continue
  ask_color            || continue
  ask_separators       || continue
  ask_heads            || continue
  ask_tails            || continue
  ask_num_lines        || continue
  ask_gap_char         || continue
  ask_frame            || continue
  ask_empty_line       || continue
  ask_extra_icons      || continue
  ask_prefixes         || continue
  ask_confirm          || continue
  ask_config_overwrite || continue
  break
done

clear

print -rP "Powerlevel10k configuration has been written to %2F$__p9k_cfg_path_u%f."
if [[ -n $config_backup ]]; then
  print -rP "The backup of the previuos version is at %3F$config_backup_u%f."
fi

if (( write_config )); then
  generate_config || return
fi

write_zshrc || return

print -rP ""
print -rP "File feature requests and bug reports at $(href https://github.com/romkatv/powerlevel10k/issues)."
print -rP "Send praise and complaints to $(href https://www.reddit.com/r/zsh)."
print -rP ""

} "$@"
