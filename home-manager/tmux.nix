{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";
    terminal = "screen-256color";
    extraConfig = ''
      set -as terminal-features ",alacritty*:RGB"
      bind -n M-r source-file /nix/store/*tmuxtmux.conf \; display "Reloaded!"
      bind C-p previous-window
      bind C-n next-window

      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5
      bind -n M-6 select-window -t 6
      bind -n M-7 select-window -t 7
      bind -n M-8 select-window -t 8
      bind -n M-9 select-window -t 9

      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R

      bind -n M-s split-window -v
      bind -n M-v split-window -h

      bind -n M-Enter new-window
      bind -n M-c kill-window
      bind -n M-q kill-session
    '';
    plugins = with pkgs; [
      tmuxPlugins.cpu
      {
        plugin = tmuxPlugins.gruvbox;
      }
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '60' # minutes
        '';
      }
    ];
  };
}