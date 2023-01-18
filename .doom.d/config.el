;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; jump to line
(map! :after evil-easymotion :map evilem-map :desc "Goto some line"
  "b" #'evil-avy-goto-line)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; setup org roam
(use-package! org-roam
  :custom
  (org-roam-directory (file-truename "~/roam"))
  (org-roam-index-file (file-truename "~/roam/index.org"))
  (org-roam-dailies-directory "daily/")
  (org-roam-dailies-capture-templates
    '(("d" "default" entry
      "* %?"
      :target (file+head "%<%Y-%m-%d>.org"
        "#+title: %<%Y-%m-%d>\n"))))
  :config
  (org-roam-setup)
  (org-roam-db-autosync-mode))

(setq centaur-tabs-buffer-show-groups t)

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; disable mouse click to move cursor position, from https://emacs.stackexchange.com/questions/48563/prevent-mouse-click-from-changing-cursor-position-while-in-insert-mode
(defun mouse-set-point (event))

;; log TODO state change into LOGBOOK drawer
(setq org-log-into_drawer "LOGBOOK")

(use-package! rime
  :custom
  (default-input-method "rime")
  (rime-show-candidate 'posframe)
  (rime-posframe-properties (list :font "Noto Sans Mono CJK SC")))

(setq delete-by-moving-to-trash t)
(when (eq system-type 'darwin)
  ;; https://github.com/DogLooksGood/emacs-rime/issues/58 customize for doom ~/.emacs.d/librime/dist
  (setq rime-librime-root (expand-file-name "librime/dist" doom-emacs-dir))
  (setq trash-directory "~/.Trash"))

;; set cjk font for unicode to fix ununified Chinese chars
(setq doom-unicode-font (font-spec :family "Noto Sans Mono CJK SC"))

(use-package! lsp-bridge)
(global-lsp-bridge-mode)
