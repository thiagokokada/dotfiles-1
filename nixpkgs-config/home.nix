{ pkgs, ... }:



with pkgs;

let
  nvim = neovim.override {
    vimAlias = true;
    withPython = true;
    configure = {
      customRC = ''
        if filereadable($HOME . "/.vimrc")
          source ~/.vimrc
        endif
        let g:ycm_rust_src_path = '${stdenv.mkDerivation {
          inherit (rustc) src;
          inherit (rustc.src) name;
          phases = ["unpackPhase" "installPhase"];
          installPhase = ''
            cp -r src $out
          '';
        }}'
      '';
      packages.nixbundle = let
        plugins = (vimPlugins.override (old: { python = python3; }));
      in with plugins; {
        # loaded on launch
        start = [
          vim-devicons
          nvim-completion-manager
          LanguageClient-neovim
          clang_complete
          pony-vim-syntax
          #deoplete-nvim
          #deoplete-jedi
          vim-trailing-whitespace
          nerdtree-git-plugin
          syntastic
          gitgutter
          airline
          nerdtree
          colors-solarized
          ack-vim
          vim-go
          vim-scala
          vim-polyglot
          syntastic
          # delimitMate
          editorconfig-vim
          ctrlp
          rust-vim
          vim-yapf
        ];
      };
    };
  };

  latexApps = [
    rubber
    (texlive.combine {
      inherit (texlive)
      scheme-basic

      # awesome cv
      xetex
      xetex-def
      unicode-math
      ucharcat
      collection-fontsextra
      fontspec

      collection-binextra
      collection-fontsrecommended
      collection-genericrecommended
      collection-latex
      collection-latexextra
      collection-latexrecommended
      collection-science
      collection-langgerman
      IEEEtran;
    })
  ];

  rubyApps = [ bundler bundix rubocop ];

  desktopApps = [
    graphicsmagick
    bench
    sshfsFuse
    sshuttle
    dino
    libreoffice-fresh
    dropbox
    #android-studio
    gimp
    inkscape
    mpd
    mpv
    firefox
    chromium
    thunderbird
    transmission_gtk
    aspell
    aspellDicts.de
    aspellDicts.fr
    aspellDicts.en
    hunspell
    hunspellDicts.en-gb-ise
    scrot
    (gajim.overrideAttrs (old: {
      patches = (old.patches or []) ++ [
        ./0001-remove-outer-paragraph.patch
      ];
    }))
    arandr
    lxappearance
    xorg.xev
    xorg.xprop
    xclip
    copyq
    xautolock
    i3lock
    (keepassx-community.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        owner = "varjolintu";
        repo = "keepassxc";
        rev = "2.2.0-browser-rc1";
        sha256 = "0sg0sq32lz6jibd3q6iiwa50rw68bccv22sm2pzx3dpl7972c0b2";
      };
      cmakeFlags = old.cmakeFlags ++ [ "-DWITH_XC_BROWSER=ON" ];
      buildInputs = old.buildInputs ++ [ boost libsodium ];
    }))
    pavucontrol
    evince
    pcmanfm
    gpodder
    valauncher
    youtube-dl
    ncmpcpp
    xclip
    screen-message
    scrot
    alacritty
  ] ++ (with gnome3; [
    gvfs
    eog
    sublime3
  ]);

  nixDevApps = [
    nix-prefetch-scripts
    pypi2nix
    go2nix
    mercurial # go2nix
    nox
    nix-repl
    nix-review
  ];

  debuggingBasicsApps = [
    gdb
    strace
  ];

  debuggingApps = [ binutils gperftools valgrind ];

  rustApps = [
    rustc
    cargo
    rustfmt
    rustracer
    (writeScriptBin "rust-doc" ''
       #! ${stdenv.shell} -e
       browser="$BROWSER"
       if [ -z "$browser" ]; then
         browser="$(type -P xdg-open || true)"
         if [ -z "$browser" ]; then
           browser="$(type -P w3m || true)"
           if [ -z "$browser" ]; then
             echo "$0: unable to start a web browser; please set \$BROWSER"
             exit 1
           fi
         fi
       fi
       exec "$browser" "${rustc.doc}/share/doc/rust/html/index.html"
    '')
  ];

  pythonDataLibs = with python3Packages; [
    ipython
    numpy
    scipy
    matplotlib
    pandas
    seaborn
  ];

in {

  home.packages = ([]
      #++ desktopApps
      #++ latexApps
      #++ rubyApps
      #++ rustApps
      #++ pythonDataLibs
      ++ debuggingApps
      ++ debuggingBasicsApps
      ++ nixDevApps
      ++ [
        nvim
        tmux
        htop
        gitAndTools.diff-so-fancy
        gitAndTools.hub
        gitAndTools.git-crypt
        gitAndTools.tig
        gitFull
        jq
        httpie
        cloc
        mosh
        cheat
        gnupg1compat
        direnv
        tree
        fzf
        exa
        ripgrep
        ag
        fd
  ]);
}