set -f
export PATH="@PATH@:$PATH"

input=$(cat)
if [ -z "$input" ]; then
  printf "Claude"
  exit 0
fi

# Colors
blue='\033[38;2;0;153;255m'
green='\033[38;2;0;175;80m'
cyan='\033[38;2;86;182;194m'
red='\033[38;2;255;85;85m'
white='\033[38;2;220;220;220m'
magenta='\033[38;2;180;140;255m'
yellow='\033[38;2;230;200;0m'
dim='\033[2m'
reset='\033[0m'

sep=" ${dim}│${reset} "

format_tokens() {
  local num=$1
  if [ "$num" -ge 1000000 ]; then
    awk "BEGIN {printf \"%.2fm\", $num / 1000000}"
  elif [ "$num" -ge 1000 ]; then
    awk "BEGIN {printf \"%.1fk\", $num / 1000}"
  else
    printf "%d" "$num"
  fi
}

model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')

input_total=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
output_total=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
total=$(( input_total + output_total ))
total_fmt=$(format_tokens "$total")

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
[ -z "$cwd" ] || [ "$cwd" = "null" ] && cwd=$(pwd)
dirname=$(basename "$cwd")

git_branch=""
git_dirty=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then
    git_dirty="*"
  fi
fi

thinking_on=$(echo "$input" | jq -r '.thinking.enabled // false')
effort_level=$(echo "$input" | jq -r '.effort.level // empty')

line="${blue}${model_name}${reset}"
line+="${sep}${cyan}${dirname}${reset}"
if [ -n "$git_branch" ]; then
  line+=" ${green}(${git_branch}${red}${git_dirty}${green})${reset}"
fi
line+="${sep}${white}${total_fmt}${reset} ${dim}tok${reset}"
line+="${sep}"
if [ "$thinking_on" = "true" ]; then
  line+="${magenta}◐ thinking${reset}"
else
  line+="${dim}◑ thinking${reset}"
fi
if [ -n "$effort_level" ]; then
  line+="${sep}${yellow}${effort_level}${reset}"
fi

printf "%b" "$line"
exit 0
