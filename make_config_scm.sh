#!/bin/sh

ROOTFS_UUID=$(sudo blkid -o value /dev/nbd0p1|head -1)
SWAP_UUID=$(sudo blkid -o value /dev/nbd0p2|head -1)
DEVICE=/dev/nbd0

# Download the unsecure ssh key used by vagrant
wget -q -O vagrant.pub https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub

cat >guix-config.scm <<EOF
;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu))
(use-modules (gnu system))
(use-modules (gnu packages certs))
(use-modules (gnu packages base))
(use-modules (gnu packages nss))
(use-modules (gnu services avahi))
(use-service-modules desktop networking ssh)

(set! *random-state* (random-state-from-platform))
(define str "0123456789abcdefghijklmnopqrstuvwxyz")
(define rnd-chr (lambda () (string-ref str (random (- (string-length str) 1)))))
(define salt (lambda () (string-append (string (rnd-chr)) (string (rnd-chr)) (string (rnd-chr)))))

;; Check if nss-certs is already in %base-packages
(define %my-base-packages
  (if (member nss-certs %base-packages)
    %base-packages ; If already present, don't add it
    (cons nss-certs %base-packages))) ; Otherwise, add it

;; This is to use only italian locales
(define my-glibc-locales
  (make-glibc-utf8-locales
   glibc
   #:locales (list "it_IT")
   #:name "glibc-italian-utf8-locales"))

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
                  (password (crypt "vagrant" (string-append "\$6\$" (salt))))
                  (supplementary-groups '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))

  ;; Packages installed system-wide.  Users can also install packages
  ;; under their own account: use 'guix search KEYWORD' to search
  ;; for packages and 'guix install PACKAGE' to install a package.
  (packages (append (list
                        my-glibc-locales
                        (specification->package "curl")
                        (specification->package "git")
                        (specification->package "htop")
                        (specification->package "screen")
                        (specification->package "stow")
                        (specification->package "unison")
                        (specification->package "vim")
                        (specification->package "rsync"))
                    %my-base-packages))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   (append (list (service dhcp-client-service-type)
                 (service openssh-service-type
                    ;; here the official unsecure Vagrant ssh key is used...
                    (openssh-configuration
                      (authorized-keys \`(("vagrant" ,(local-file "vagrant.pub")))))))

           ;; This is the default list of services we
           ;; are appending to.
           %base-services))

  ;; Authorize vagrant to run sudo without password.
  (sudoers-file
    (plain-file "sudoers"
                 (string-append (plain-file-content %sudoers-specification)
                                "vagrant ALL=(ALL) NOPASSWD: ALL\\n")))

  (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (targets (list "$DEVICE"))
                (keyboard-layout keyboard-layout)))
  (swap-devices (list (swap-space
                        (target (uuid
                                 "$SWAP_UUID")))))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/")
                         (device (uuid
                                  "$ROOTFS_UUID"
                                  'ext4))
                         (type "ext4")) %base-file-systems)))
EOF
