;; This is an operating system configuration generated
;; by the graphical installer.
;;
;; Once installation is complete, you can learn and modify
;; this file to tweak the system configuration, and pass it
;; to the 'guix system reconfigure' command to effect your
;; changes.


;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu) (guix channels) (nongnu packages linux))
(use-service-modules cups desktop networking ssh xorg)

;;
;; This is a simple customization that includes nonguix repo
;; and its subs server.
;;
(define %my-services
    (modify-services %desktop-services

             (guix-service-type config => (guix-configuration
               (inherit config)
               (substitute-urls
                (append (list "http://substitutes.lovergine.com https://substitutes.nonguix.org" "https://guix.bordeaux.inria.fr" "https://hydra-guix-129.guix.gnu.org")
                  (@@ (guix scripts substitute) %default-substitute-urls)))
               (authorized-keys
                (append (list (local-file "./nonguix-signing-key.pub") (local-file "./ladestem-signing-key.pub") (local-file "./inria-signing-key.pub"))
                  %default-authorized-guix-keys))))

	     (elogind-service-type config => (elogind-configuration 
               	(inherit config)
		(handle-lid-switch 'ignore)
		(handle-lid-switch-external-power 'ignore)
		(handle-lid-switch-docked 'ignore)))

	     (gdm-service-type config => (gdm-configuration
		(inherit config)
		(auto-suspend? #f))) )
)

(set! %default-channels (list 
      (channel
        (name 'nonguix)
        (url "https://gitlab.com/nonguix/nonguix.git")
        (branch "master")
        (introduction
          (make-channel-introduction
            "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
            (openpgp-fingerprint
              "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
      (channel
        (name 'guix)
        (url "https://codeberg.org/guix/guix.git")
        (branch "master")
        (introduction
          (make-channel-introduction
            "9edb3f66fd807b096b48283debdcddccfea34bad"
            (openpgp-fingerprint
              "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
))

(operating-system
  (kernel linux)
  (firmware (list linux-firmware))
  (locale "it_IT.utf8")
  (timezone "Europe/Rome")
  (keyboard-layout (keyboard-layout "it" "us"))
  (host-name "mithrandir")

  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                  (name "frankie")
                  (comment "Francesco Paolo Lovergine")
                  (group "users")
                  (home-directory "/home/frankie")
                  (supplementary-groups '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))

  ;; Packages installed system-wide.  Users can also install packages
  ;; under their own account: use 'guix search KEYWORD' to search
  ;; for packages and 'guix install PACKAGE' to install a package.
  (packages (append (list (specification->package "awesome")
                          (specification->package "htop")
			  (specification->package "vim")
			  (specification->package "screen")
			  (specification->package "git")
			  (specification->package "rsync")
			  (specification->package "gcc-toolchain")
			  (specification->package "stow")
			  (specification->package "unison")
			  (specification->package "emacs")
			  (specification->package "flatpak")
			  (specification->package "glibc-locales"))
                    %base-packages))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   (append (list (service gnome-desktop-service-type)
                 ;; To configure OpenSSH, pass an 'openssh-configuration'
                 ;; record as a second argument to 'service' below.
                 (service openssh-service-type)
                 (service cups-service-type)
                 (set-xorg-configuration
                  (xorg-configuration (keyboard-layout keyboard-layout)))
                 )
           ;; This is the custom list of services we
           ;; are appending to.
           %my-services))

  (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (targets (list "/dev/sda"))
                (keyboard-layout keyboard-layout)))
  (swap-devices (list (swap-space
                        (target (uuid
                                 "1f0572f0-535f-4594-a15a-e483bdb49816")))))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/")
                         (device (uuid
                                  "ecfedbfd-1d33-4376-8bcf-77f9317a6e5d"
                                  'ext4))
                         (type "ext4")) %base-file-systems)))
