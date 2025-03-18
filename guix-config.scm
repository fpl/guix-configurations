;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu))
(use-modules (gnu system))
(use-modules (gnu services avahi))
(use-service-modules desktop networking ssh)

(set! *random-state* (random-state-from-platform))
(define str "0123456789abcdefghijklmnopqrstuvwxyz")
(define rnd-chr (lambda () (string-ref str (random (- (string-length str) 1)))))
(define salt (lambda () (string-append (string (rnd-chr)) (string (rnd-chr)) (string (rnd-chr)))))

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
           ;; are appending to.
           %base-services))

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
