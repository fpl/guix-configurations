;;
;; This is a configuration files for a Virtualbox desktop Guix system
;; of reasonable age.
;;

;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu))
(use-service-modules cups desktop networking ssh xorg)

(operating-system
  (locale "it_IT.utf8")
  (timezone "Europe/Rome")
  (keyboard-layout (keyboard-layout "it" "us"))
  (host-name "galadriel")

  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                  (name "frankie")
                  (comment "Francesco P Lovergine")
                  (group "users")
                  (home-directory "/home/frankie")
                  (supplementary-groups '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))

  ;; Check if nss-certs is already in %base-packages
  (define %my-base-packages
    (if (member nss-certs %base-packages) 
      %base-packages ; If already present, don't add it
      (cons nss-certs %base-packages))) ; Otherwise, add it

  ;; Packages installed system-wide.  Users can also install packages
  ;; under their own account: use 'guix search KEYWORD' to search
  ;; for packages and 'guix install PACKAGE' to install a package.
  (packages (append (list 
                      (specification->package "glibc-locales")
                      (specification->package "rsync")
                      (specification->package "curl")
                      (specification->package "git")
                      (specification->package "htop")
                      (specification->package "screen")
                      (specification->package "stow")
                      (specification->package "unison")
                    )
                    %my-base-packages))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   (append (list (service gnome-desktop-service-type)

                 ;; To configure OpenSSH, pass an 'openssh-configuration'
                 ;; record as a second argument to 'service' below.
                 (service openssh-service-type)
                 (service cups-service-type)
                 (set-xorg-configuration
                  (xorg-configuration (keyboard-layout keyboard-layout))))

           ;; This is the default list of services we
           ;; are appending to.
           %desktop-services))
  (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (targets (list "/dev/sda"))
                (keyboard-layout keyboard-layout)))
  (swap-devices (list (swap-space
                        (target (uuid
                                 "c031f6ac-9158-4ab3-957f-6f2c4156eff2")))))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/")
                         (device (uuid
                                  "36beb536-1375-42dc-833b-a4f978c755ab"
                                  'ext4))
                         (type "ext4")) %base-file-systems)))
