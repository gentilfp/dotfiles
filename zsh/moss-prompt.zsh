# zsh/moss-prompt.zsh: MOSS minimal override for powerlevel10k.
# Sourced from .p10k.zsh just before the final reload. Hexes from
# moss/tokens/moss.json. Needs a truecolor terminal.

local bg='#0D0F0C' fg='#D7D9D2' muted='#70766B' faint='#4B5147'
local moss='#7E9273' olive='#9A9968' ochre='#B69A64' red='#C06B63'

# Left: directory, git, then a prompt char on its own line.
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline prompt_char)

# Flat: no fills. Every segment becomes plain text in muted, then we color
# the ones that matter. The old black-on-fill foregrounds would be invisible.
local v
for v in ${(k)parameters[(I)POWERLEVEL9K_*_BACKGROUND]}; do typeset -g $v=; done
for v in ${(k)parameters[(I)POWERLEVEL9K_*_FOREGROUND]}; do typeset -g $v=$muted; done
typeset -g POWERLEVEL9K_BACKGROUND=

# No powerline shapes, no frame, no dotted gap.
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=' '
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=' '
# Same-background segments use the subsegment separator, so the dir/git divider lives here.
typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR="%F{$faint} \uE0B1 %f"
typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR=' '
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_PROMPT_{FIRST_SEGMENT_START,LAST_SEGMENT_END}_SYMBOL=
typeset -g POWERLEVEL9K_MULTILINE_{FIRST,NEWLINE,LAST}_PROMPT_{PREFIX,SUFFIX}=
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR=' '
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

# Directory: path muted, last part in moss.
typeset -g POWERLEVEL9K_DIR_FOREGROUND=$muted
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=$faint
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=$moss
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=false
typeset -g POWERLEVEL9K_DIR_{WORK,NON_EXISTENT}_FOREGROUND=$muted
typeset -g POWERLEVEL9K_DIR_WORK_NOT_WRITABLE_FOREGROUND=$ochre
typeset -g POWERLEVEL9K_DIR_VISUAL_IDENTIFIER_EXPANSION=
typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_EXPANSION=
typeset -g POWERLEVEL9K_VCS_PREFIX=

# Git: colors are set in my_git_formatter (clean moss, modified ochre,
# untracked olive, conflicted red).
typeset -g POWERLEVEL9K_VCS_{CLEAN,MODIFIED,UNTRACKED,CONFLICTED,LOADING}_FOREGROUND=$muted

# Prompt char: moss when OK, red after a failed command.
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$moss
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$red
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'

# Right side: quiet, only errors stand out.
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs)
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_OK_PIPE=false
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$red
typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=$red
typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=$red
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$ochre
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX=
