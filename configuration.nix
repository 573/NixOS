
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports = (import ./settings.nix).imports;

  networking = {
    hostName = (import ./settings.nix).hostname;
    networkmanager.enable = (import ./settings.nix).networkmanager.enable;
    wireless.enable = false;  # Enables wireless support via wpa_supplicant.
  };
  
  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  time.timeZone = (import ./settings.nix).timezone;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    wget
    curl
    (import ./vim-config.nix)
    tmux
    coreutils
    file
    htop
    lsof
    psmisc
    rsync
    git
    acl
    mkpasswd
    unzip
    python3
    lm_sensors
    nmap
  ];

  boot = {
    loader.grub = {
      enable = true;
      # Use the GRUB 2 boot loader.
      version = 2;
      # efiSupport = true;
      # efiInstallAsRemovable = true;
      # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
      device = (import ./settings.nix).grub.device;
      memtest86.enable = true;
    };
    # boot.loader.efi.efiSysMountPoint = "/boot/efi";

    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      # Overwrite free'd memory
      #"page_poison=1"

      # Disable legacy virtual syscalls
      #"vsyscall=none"

      # Disable hibernation (allows replacing the running kernel)
      "nohibernate"
    ];

    kernel.sysctl = {
      # Prevent replacing the running kernel image w/o reboot
      "kernel.kexec_load_disabled" = true;

      # Disable bpf() JIT (to eliminate spray attacks)
      #"net.core.bpf_jit_enable" = mkDefault false;

      # ... or at least apply some hardening to it
      "net.core.bpf_jit_harden" = true;

      # Raise ASLR entropy
      "vm.mmap_rnd_bits" = 32;
    };

    tmpOnTmpfs = true;
  };

  fileSystems."/".options = [ "acl" ];

  zramSwap = {
    enable = true;
    memoryPercent = 40;
  };

  ## WARNING: Don't try to hibernate when you have at least one swap partition with this option enabled!
  ## We have no way to set the partition into which hibernation image is saved, so if your image ends up on an encrypted one you would lose it!
  ## WARNING #2: Do not use /dev/disk/by-uuid/… or /dev/disk/by-label/… as your swap device when using randomEncryption
  ## as the UUIDs and labels will get erased on every boot when the partition is encrypted. Best to use /dev/disk/by-partuuid/…
  #swapDevices.*.randomEncryption = {
  #  enable = true;
  #  cipher = <run cryptsetup benchmark>
  #};

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  environment.etc = {
    tmux = {
      target = "tmux.conf";
      text = "new-session";
    };
    lustrate = {
      # Can we have this permanently enabled?
      # What about /var/lib/docker ?? Other locations that we need to maintain on a working system?
      enable = false;
      target = "NIXOS_LUSTRATE";
      text = ''
        etc/nixos
        opt
        home
      '';
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "no";
      forwardX11 = false;
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
      extraConfig = ''
        UsePrivilegeSeparation yes
        StrictModes yes
        TCPKeepAlive yes
        ClientAliveInterval 20
        ClientAliveCountMax 3
        UseDNS no
        # NixOS builds SSH without Kerberos support for now.
        GSSAPIAuthentication no
        KerberosAuthentication no
      '';
    };

    journald = {
      rateLimitBurst = 1000;
      rateLimitInterval = "5s";
    };

    # See man logind.conf
    logind = {
      extraConfig = ''
        HandlePowerKey=poweroff
        PowerKeyIgnoreInhibited=yes
      '';
    };

  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account.
  users.mutableUsers = false;

  system.autoUpgrade.enable = true;

  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 90d";
    };
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "17.09"; # Did you read the comment?

}

