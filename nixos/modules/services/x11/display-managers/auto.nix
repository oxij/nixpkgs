{ config, lib, ... }:

with lib;

let

  dmcfg = config.services.xserver.displayManager;
  cfg = dmcfg.auto;

in

{

  ###### interface

  options = {

    services.xserver.displayManager.auto = {

      enable = mkOption {
        default = false;
        description = ''
          Whether to enable the fake "auto" display manager, which
          automatically logs in the user specified in the
          <option>user</option> option.  This is mostly useful for
          automated tests.
        '';
      };

      user = mkOption {
        default = "root";
        description = "The user account to login automatically.";
      };

    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    services.xserver.displayManager.slim = {
      enable = true;
      autoLogin = true;
      defaultUser = cfg.user;
    };

    # lightdm by default doesn't allow auto login for root, which is
    # required by some nixos tests. Override it here.
    security.pam.services.lightdm-autologin.text = lib.mkForce ''
        auth     requisite pam_nologin.so
        auth     required  pam_succeed_if.so quiet
        auth     required  pam_permit.so

        account  include   lightdm

        password include   lightdm

        session  include   lightdm
    '';

  };

}
