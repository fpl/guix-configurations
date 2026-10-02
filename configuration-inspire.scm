;;==========================================
;; This is the inspire custom configuration
;;==========================================

;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu) 
	     (guix channels) 
	     (nongnu packages linux))
(use-service-modules cups desktop networking ssh xorg)

;;
;; This is the customization of default channels with both new guix and 
;; non guix channels
;;
(define %my-channels (list 
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
      (channel
        (name 'guix-science)
        (url "https://codeberg.org/guix-science/guix-science.git")
        (branch "master")
        (introduction
          (make-channel-introduction
            "b1fe5aaff3ab48e798a4cce02f0212bc91f423dc"
            (openpgp-fingerprint
              "CA4F 8CF4 37D7 478F DA05  5FD4 4213 7701 1A37 8446"))))
))

;;
;; A few customization of standard desktop services
;;
(define %my-services
    (modify-services %desktop-services

         ;; This is to add additional subs servers with their keys
         (guix-service-type config => (guix-configuration
               (inherit config)
               (channels %my-channels)
               (substitute-urls
                (append (list "http://substitutes.lovergine.com"
                              "https://substitutes.nonguix.org"
                              "https://guix.bordeaux.inria.fr" ; guix-science
                              "https://hydra-guix-129.guix.gnu.org")
                  (@@ (guix scripts substitute) %default-substitute-urls)))
               (authorized-keys
                (append (list (local-file "keys/nonguix-signing-key.pub")
                              (local-file "keys/ladestem-signing-key.pub")
                              (local-file "keys/inria-signing-key.pub"))
                  %default-authorized-guix-keys))))))

(operating-system
  (kernel linux)
  (kernel-arguments '("pci=noaer"))
  (firmware (list linux-firmware))
  (locale "it_IT.utf8")
  (timezone "Europe/Rome")
  (keyboard-layout (keyboard-layout "it" "us"))
  (host-name "inspire")


  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                  (name "frankie")
                  (comment "Francesco P Lovergine")
                  (group "users")
                  (home-directory "/home/frankie")
                  (supplementary-groups '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   (append (list (service gnome-desktop-service-type)

                 ;; To configure OpenSSH, pass an 'openssh-configuration'
                 ;; record as a second argument to 'service' below.
                 (service openssh-service-type)
                 (service cups-service-type)
		 (service bluetooth-service-type)
                 (set-xorg-configuration
                  (xorg-configuration (keyboard-layout keyboard-layout))))

           ;; This is the list of services we
           ;; are appending to.
           %my-services))
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets (list "/boot/efi"))
                (keyboard-layout keyboard-layout)))
  (swap-devices (list (swap-space
                        (target (uuid
                                 "1cea309e-8268-4767-8004-798aaaa907e8")))))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "7C5D-C3F3"
                                       'fat32))
                         (type "vfat"))
                       (file-system
                         (mount-point "/")
                         (device (uuid
                                  "1955acb1-d4e9-4f00-8730-732efafd3eff"
                                  'ext4))
                         (type "ext4")) %base-file-systems)))
