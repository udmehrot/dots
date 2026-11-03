fzf_theme_opts="\
--color=bg+:#26233a
--color=bg:#191724
--color=spinner:#e0def4
--color=hl:#eb6f92
--color=fg:#e0def4
--color=header:#eb6f92
--color=info:#ebbcba
--color=pointer:#e0def4
--color=marker:#908caa
--color=fg+:#e0def4
--color=prompt:#ebbcba
--color=hl+:#eb6f92
--color=selected-bg:#26233a
--color=border:#403d52
--color=label:#e0def4"

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS
}$fzf_theme_opts"
