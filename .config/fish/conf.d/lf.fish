# {{{1 Autocompletion for fish shell.
complete -c lf -o command -r -d 'command to execute on client initialization'
complete -c lf -o config -r -d 'path to the config file (instead of the usual paths)'
complete -c lf -o cpuprofile -r -d 'path to the file to write the CPU profile'
complete -c lf -o doc -d 'show documentation'
complete -c lf -o last-dir-path -r -d 'path to the file to write the last dir on exit (to use for cd)'
complete -c lf -o memprofile -r -d 'path to the file to write the memory profile'
complete -c lf -o remote -x -d 'send remote command to server'
complete -c lf -o selection-path -r -d 'path to the file to write selected files on open (to use as open file dialog)'
complete -c lf -o server -d 'start server (automatic)'
complete -c lf -o single -d 'start a client without server'
complete -c lf -o version -d 'show version'
complete -c lf -o help -d 'show help'

# {{{1 lfcd
# https://github.com/gokcehan/lf/blob/master/etc/lfcd.fish
# Change working dir in fish to last dir in lf on exit (adapted from ranger).
#
# You may put this file to a directory in $fish_function_path variable:
#
#     mkdir -p ~/.config/fish/functions
#     ln -s "/path/to/lfcd.fish" ~/.config/fish/functions
#
# You may also like to assign a key to this command:
#
#     bind \co 'set old_tty (stty -g); stty sane; lfcd; stty $old_tty; commandline -f repaint'
#
# You may put this in a function called fish_user_key_bindings.
function lfcd
    set tmp (mktemp)
    lf -last-dir-path=$tmp $argv
    if test -f "$tmp"
        set dir (cat $tmp)
        rm -f $tmp
        if test -d "$dir"
            if test "$dir" != (pwd)
                cd $dir
            end
        end
    end
end

alias lc=lfcd

# {{{1 file icons
set -gx LF_ICONS "\
tw=:\
st=:\
ow=:\
dt=:\
di=:\
fi=:\
ln=:\
or=:\
ex=:\
*.c=:\
*.cc=:\
*.clj=:\
*.coffee=:\
*.cpp=:\
*.css=:\
*.d=:\
*.dart=:\
*.erl=:\
*.exs=:\
*.fs=:\
*.go=:\
*.h=:\
*.hh=:\
*.hpp=:\
*.hs=:\
*.html=:\
*.java=:\
*.jl=:\
*.js=:\
*.json=:\
*.lua=:\
*.md=:\
*.php=:\
*.pl=:\
*.pro=:\
*.py=:\
*.rb=:\
*.rs=:\
*.scala=:\
*.ts=:\
*.vim=:\
*.cmd=:\
*.ps1=:\
*.sh=:\
*.bash=:\
*.zsh=:\
*.fish=:\
*.tar=:\
*.tgz=:\
*.arc=:\
*.arj=:\
*.taz=:\
*.lha=:\
*.lz4=:\
*.lzh=:\
*.lzma=:\
*.tlz=:\
*.txz=:\
*.tzo=:\
*.t7z=:\
*.zip=:\
*.z=:\
*.dz=:\
*.gz=:\
*.lrz=:\
*.lz=:\
*.lzo=:\
*.xz=:\
*.zst=:\
*.tzst=:\
*.bz2=:\
*.bz=:\
*.tbz=:\
*.tbz2=:\
*.tz=:\
*.deb=:\
*.rpm=:\
*.jar=:\
*.war=:\
*.ear=:\
*.sar=:\
*.rar=:\
*.alz=:\
*.ace=:\
*.zoo=:\
*.cpio=:\
*.7z=:\
*.rz=:\
*.cab=:\
*.wim=:\
*.swm=:\
*.dwm=:\
*.esd=:\
*.jpg=:\
*.jpeg=:\
*.mjpg=:\
*.mjpeg=:\
*.gif=:\
*.bmp=:\
*.pbm=:\
*.pgm=:\
*.ppm=:\
*.tga=:\
*.xbm=:\
*.xpm=:\
*.tif=:\
*.tiff=:\
*.png=:\
*.svg=:\
*.svgz=:\
*.mng=:\
*.pcx=:\
*.mov=:\
*.mpg=:\
*.mpeg=:\
*.m2v=:\
*.mkv=:\
*.webm=:\
*.ogm=:\
*.mp4=:\
*.m4v=:\
*.mp4v=:\
*.vob=:\
*.qt=:\
*.nuv=:\
*.wmv=:\
*.asf=:\
*.rm=:\
*.rmvb=:\
*.flc=:\
*.avi=:\
*.fli=:\
*.flv=:\
*.gl=:\
*.dl=:\
*.xcf=:\
*.xwd=:\
*.yuv=:\
*.cgm=:\
*.emf=:\
*.ogv=:\
*.ogx=:\
*.aac=:\
*.au=:\
*.flac=:\
*.m4a=:\
*.mid=:\
*.midi=:\
*.mka=:\
*.mp3=:\
*.mpc=:\
*.ogg=:\
*.ra=:\
*.wav=:\
*.oga=:\
*.opus=:\
*.spx=:\
*.xspf=:\
*.pdf=:\
*.nix=:\
*gruntfile.coffee=:\
*gruntfile.js=:\
*gruntfile.ls=:\
*gulpfile.coffee=:\
*gulpfile.js=:\
*gulpfile.ls=:\
*mix.lock=:\
*dropbox=:\
*.ds_store=:\
*.gitconfig=:\
*.gitignore=:\
*.gitattributes=:\
*.gitlab-ci.yml=:\
*.bashrc=:\
*.zshrc=:\
*.zshenv=:\
*.zprofile=:\
*.vimrc=:\
*.gvimrc=:\
*_vimrc=:\
*_gvimrc=:\
*.bashprofile=:\
*favicon.ico=:\
*license=:\
*node_modules=:\
*react.jsx=:\
*procfile=:\
*dockerfile=:\
*docker-compose.yml=:\
*rakefile=:\
*config.ru=:\
*gemfile=:\
*makefile=:\
*cmakelists.txt=:\
*robots.txt=ﮧ:\
*package.json=ﯵ\
"

# vim:foldmethod=marker
