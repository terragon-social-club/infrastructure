;; Hacker mode
(setq ring-bell-function 'ignore)
(setq inhibit-splash-screen t)
(setq inhibit-startup-message t)
(menu-bar-mode -1)

;; Don't leave junk files everywhere
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

;; Automatic shit
(require 'package)
(require 'cl)

;; Scrolling Smooth
;; scroll one line at a time (less "jumpy" than defaults)
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1))) ;; one line at a time
(setq mouse-wheel-progressive-speed nil) ;; don't accelerate scrolling
(setq mouse-wheel-follow-mouse 't) ;; scroll window under mouse
(setq scroll-step 1) ;; keyboard scroll one line at a time

(defvar elpa-packages '(
                        company
			magit
			web-mode
			company-web
			yaml-mode
                        ruby-mode
                        rhtml-mode
			markdown-mode
			danneskjold-theme
                        sourcerer-theme
			key-chord
			helm
                        flycheck
                        tide
                        projectile
                        helm-projectile
                        neotree
                        flymake-ruby
                        inkpot-theme
                        ujelly-theme
                        terraform-mode
                        salt-mode
                        groovy-mode
                        ))

(defun cfg:install-packages ()
  (let ((pkgs (remove-if #'package-installed-p elpa-packages)))
    (when pkgs
      (package-refresh-contents)
      (dolist (p elpa-packages)
        (package-install p)))))

;(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)

(package-initialize)

(cfg:install-packages)

;; Trust
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.

 
 '(custom-safe-themes
   (quote
     ("53a9ec5700cf2bb2f7059a584c12a5fdc89f7811530294f9eaf92db526a9fb5f" "1bd383f15ee7345c270b82c5e41554754b2a56e14c2ddaa2127c3590d0303b95" "8bb8a5b27776c39b3c7bf9da1e711ac794e4dc9d43e32a075d8aa72d6b5b3f59" "243bd9824b2a2203c4cf22e306e4fba73f9e6d6f0b032176876980da471bdca5" "b2db1708af2a7d50cac271be91908fffeddb04c66cb1a853fff749c7ad6926ae" "01ce486c3a7c8b37cf13f8c95ca4bb3c11413228b35676025fdf239e77019ea1" default)))
 '(package-selected-packages
   (quote
    (zone-select zone-rainbow zone-nyan flymake-ruby bundler neotree helm-projectile projectile tide flycheck helm key-chord danneskjold-theme markdown-mode yaml-mode company-web web-mode magit alchemist company))))

;; Theme
(load-theme 'ujelly)
(require 'key-chord)

;; Customizations
(key-chord-mode 1)
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1))) ;; one line at a time
(setq scroll-step 1) ;; keyboard scroll one line at a time

(require 'helm-config)
(global-set-key (kbd "M-x") 'helm-M-x)
(global-set-key (kbd "C-x C-f") 'helm-find-files)
(global-set-key (kbd "C-x g") 'magit-status)

(global-company-mode 1)

(setq company-idle-delay 0.1)
(setq company-tooltip-limit 10)
(setq company-minimum-prefix-length 2)
(setq company-tooltip-flip-when-above t)

(require 'flymake-ruby)
(add-hook 'ruby-mode-hook 'flymake-ruby-load)

(projectile-global-mode)
(require 'helm-projectile)
(helm-projectile-on)
(global-set-key [f8] 'neotree-toggle)

(setq-default indent-tabs-mode nil)
(setq tab-width 2)

(require 'web-mode)

;(add-to-list 'load-path "~/.emacs.d/custom")
;(require 'flycheck-typescript-tslint)

(defun setup-tide-mode ()
  (interactive)
  (tide-setup)
  (flycheck-mode t)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (eldoc-mode t)
  (setq typescript-indent-level 2))

;; aligns annotation to the right hand side
(setq company-tooltip-align-annotations t)

;; formats the buffer before saving
(add-hook 'before-save-hook 'tide-format-before-save)

;; see https://github.com/Microsoft/TypeScript/blob/cc58e2d7eb144f0b2ff89e6a6685fb4deaa24fde/src/server/protocol.d.ts#L421-473 for the full list available options

(add-hook 'typescript-mode-hook #'setup-tide-mode)

(setq js-indent-level 2)

(defun my-web-mode-hook ()
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-code-indent-offset 2)
  (setq web-mode-indent-style 1))

(add-hook 'web-mode-hook  'my-web-mode-hook)
(setq tide-tsserver-process-environment '("TSS_LOG=-level verbose -file /tmp/tss.log"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(setq tide-tsserver-process-environment '("TSS_LOG=-level verbose"))
