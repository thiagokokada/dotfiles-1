{ pkgs, ... }:



with pkgs;

let
  mybrowser = firefox;


  latexApps = [
    rubber

    (texlive.combine {
      inherit (texlive)
      scheme-basic

      # awesome cv
      xetex
      unicode-math
      ucharcat
      collection-fontsextra
      fontspec

      collection-binextra
      collection-fontsrecommended
      collection-latex
      collection-latexextra
      collection-latexrecommended
      collection-langgerman
      IEEEtran
      algorithm2e;
    })
  ];


  rubyApps = [ bundler bundix rubocop ];

  desktopApps = [
    qt5.qttools
    radare2
    league-of-moveable-type
    dejavu_fonts
    ubuntu_font_family
    unifont
    #emojione

    gnome3.defaultIconTheme
    hicolor_icon_theme
    #kmymoney

    #remmina
    graphicsmagick
    hyperfine
    sshfsFuse
    sshuttle
    #libreoffice
    dropbox
    #android-studio
    gimp
    #inkscape
    mpd
    mpv
    youtube-dl
    mybrowser
    chromium
    aspell
    aspellDicts.de
    aspellDicts.fr
    aspellDicts.en
    hunspell
    hunspellDicts.en-gb-ise
    urlview
    dino
    xorg.xev
    xorg.xprop
    xclip
    keepassx-community
    lxqt.pavucontrol-qt
    gpodder
    ncmpcpp
    xclip
    screen-message
    alacritty
    sublime3

    kmail
    kdeApplications.kontact
    kdeApplications.kaddressbook
    kdeApplications.korganizer
    kdeconnect
    kdeApplications.spectacle
    kdeApplications.gwenview
    kdeApplications.dolphin
    kdeApplications.okular
    kdeApplications.akonadi-contacts
    kdeApplications.akonadi-calendar
    kdeApplications.akonadi-mime 
    kdeApplications.akonadi-notes 
    kdeFrameworks.networkmanager-qt
  ] ++ (with nur.repos.mic92; [
    inxi
    conky-symbols
    inconsolata-nerdfonts
    gdbgui
  ]);

  nixDevApps = [
    nix-prefetch-scripts
    pypi2nix
    go2nix
    mercurial # go2nix
    nox
    nur.repos.mic92.nix-review-unstable
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
       exec "${mybrowser}" "${rustc.doc}/share/doc/rust/html/index.html"
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

  dotfilesPath = file: ".homesick/repos/dotfiles/home/${file}";

in {
  programs.git = {
    enable = true;
    userEmail = "joerg@thalheim.io";
    userName = "Joerg Thalheim";
    package = gitFull;
    signing = {
      #signByDefault = builtins.pathExists ../../.gnupg/S.gpg-agent;
      key = "CA4106B8D7CC79FA";
    };
  };
 
  fonts.fontconfig.enableProfileFonts = true;

  home.packages = ([]
      ++ desktopApps
      ++ latexApps
      #++ rubyApps
      #++ rustApps
      #++ pythonDataLibs
      ++ debuggingApps
      ++ debuggingBasicsApps
      ++ nixDevApps
      ++ [
        myvim
        asciinema

        flatpak

        # python language server + plugins
        (python36.withPackages(ps: [ ps.pyls-mypy ps.pyls-isort ps.pyls-black ]))

        nodePackages.jsonlint
        nodePackages.ocaml-language-server
        ocamlPackages_latest.merlin
        rustup

        tmux
        htop
        psmisc
        lesspipe
        expect
        gitAndTools.diff-so-fancy
        gitAndTools.hub
        gitAndTools.tig
        jq
        httpie
        cloc
        mosh
        cheat
        gnupg1compat
        direnv
        fzf
        exa
        fd
      ]);
}
