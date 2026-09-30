;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu))
(use-modules (guix channels))
(use-modules (gnu system))
(use-modules (gnu services avahi))
(use-service-modules desktop networking ssh)

(set! *random-state* (random-state-from-platform))
(define str "0123456789abcdefghijklmnopqrstuvwxyz")
(define rnd-chr (lambda () (string-ref str (random (- (string-length str) 1)))))
(define salt (lambda () (string-append (string (rnd-chr)) (string (rnd-chr)) (string (rnd-chr)))))

;; Base services with additional substitute servers and their keys
(define %my-services
  (modify-services %base-services
    (guix-service-type config => (guix-configuration
               (inherit config)
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

;; Channels: guix, nonguix and guix-science
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
      (channel
        (name 'guix-science)
        (url "https://codeberg.org/guix-science/guix-science.git")
        (branch "master")
        (introduction
          (make-channel-introduction
            "b1fe5aaff3ab48e798a4cce02f0212bc91f423dc"
            (openpgp-fingerprint
              "CA4F 8CF4 37D7 478F DA05  5FD4 4213 7701 1A37 8446"))))))

(operating-system
  (locale "en_US.utf8")
  (timezone "Europe/Rome")
  (keyboard-layout (keyboard-layout "us" "intl"))
  (host-name "guix")

  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                  (name "vagrant")
                  (comment "Vagrant user")
                  (group "users")
                  (home-directory "/home/vagrant")
                  (password (crypt "vagrant" (string-append "$6$" (salt))))
                  (supplementary-groups '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))

  ;; Packages installed system-wide.  Users can also install packages
  ;; under their own account: use 'guix search KEYWORD' to search
  ;; for packages and 'guix install PACKAGE' to install a package.
  (packages (append (list (specification->package "nss-certs")
                          (specification->package "rsync"))
                    %base-packages))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   (append (list (service dhcp-client-service-type)
                 (service openssh-service-type
                    ;; here the official unsecure Vagrant ssh key is used...
                    (openssh-configuration
                      (authorized-keys `(("vagrant" ,(local-file "vagrant.pub")))))))

           ;; This is the default list of services we
           ;; are appending to (with our substitute servers).
           %my-services))

  ;; Authorize vagrant to run sudo without password.
  (sudoers-file
    (plain-file "sudoers"
                 (string-append (plain-file-content %sudoers-specification)
                                "vagrant ALL=(ALL) NOPASSWD: ALL\n")))

  (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (targets (list "/dev/nbd0"))
                (keyboard-layout keyboard-layout)))
  (swap-devices (list (swap-space
                        (target (uuid
                                 "a2fb3148-1f87-472d-82e5-6e8d81f4d551")))))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/")
                         (device (uuid
                                  "1a5876a0-ec35-483d-a4cf-88c693903f13"
                                  'ext4))
                         (type "ext4")) %base-file-systems)))
