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
(menu-bar-mode -1)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
;; (setq display-line-numbers-type 'relative)
;;
(setq display-line-numbers-type 'visual)

;; List of suggestions from which-key is partially covered by status line
;; https://github.com/doomemacs/doomemacs/issues/5622
(setq which-key-allow-imprecise-window-fit nil)

(after! evil
  (setq evil-auto-indent nil))
(use-package! evil-snipe
  :custom
  (evil-snipe-scope 'buffer))

(after! org
  (map! :map org-mode-map :leader :prefix "l"
        :desc "" :n "o" #'+org/insert-item-below
        :desc "" :n "O" #'+org/insert-item-above
        )
  )
(map! :after org-roam :leader :desc "Search Org Roam notes" :n "s n"
      #'+default/org-roam-search)
;; jump to line
(map! :after evil-easymotion :map evilem-map :desc "Goto some line"
      "b" #'evil-avy-goto-line)

(setq my-roam-dir (file-truename "~/roam/"))
(setq my-roam-dailies-dir "journals/")
;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")
(setq org-agenda-files
      (list org-directory my-roam-dir (file-name-concat my-roam-dir my-roam-dailies-dir)))

(setq my-roam-dailies-file-path (file-name-concat my-roam-dailies-dir "%<%Y-%m-%d>.org"))
;; setup org roam
(use-package! org-roam
  :custom
  (org-roam-directory my-roam-dir)
  (org-roam-dailies-directory my-roam-dailies-dir)
  (org-roam-dailies-capture-templates
   '(("d" "default" entry
      "* %?"
      :target (file+head "%<%Y-%m-%d>.org"
                         "#+title: %<%Y-%m-%d>\n"))))
  (org-roam-capture-ref-templates
   '(
     ("r" "ref" plain "%?" :target
      (file+head "${slug}.org" "#+title: ${title}")
      :unnarrowed t)
     ("d" "daily entry" entry "* TODO [[${ref}][${title}]]
SCHEDULED: %t
:PROPERTIES:
:CAPTURED: %U
:ROAM_REFS: ${ref}
:END:
- tags ::  %?

${body}
" :target
(file+head (lambda() my-roam-dailies-file-path) "#+title: %<%Y-%m-%d>
" ))))
  :config
  (org-roam-setup)
  (org-roam-db-autosync-mode))

;; mimic +default/org-notes-search
(defun +default/org-roam-search (query)
  "Perform a text search on `org-roam-directory'."
  (interactive
   (list (if (doom-region-active-p)
             (buffer-substring-no-properties
              (doom-region-beginning)
              (doom-region-end))
           "")))
  (+default/search-project-for-symbol-at-point
   query org-roam-directory))

;; TODO: remove this
(defun my-org-roam-search ()
  (+vertico/project-search nil nil org-roam-directory))

(map! :after org-roam :leader :desc "Search Org Roam notes" :n "s n"
      #'+default/org-roam-search)

;; (setq centaur-tabs-buffer-show-groups t)

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
;; (defun mouse-set-point (event))

;; log TODO state change into LOGBOOK drawer
(setq org-log-into_drawer "LOGBOOK")

(defun convert-inter-wikis (inter-wikis)
  (let (value)
    (dolist (el (split-string inter-wikis "\n") value)
      (push (split-string  el " ") value))))

(setq my-org-abbrev-links "wp https://en.wikipedia.org/wiki/
wpmeta https://meta.wikipedia.org/wiki/
doku https://www.dokuwiki.org/
rfc https://tools.ietf.org/html/rfc
man http://man.cx/
amazon https://www.amazon.com/dp/
paypal https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&amp;business=
phpfn https://secure.php.net/
google.de https://www.google.de/search?q=
go https://www.google.com/search?q=
arch https://wiki.archlinux.org/index.php/
aur https://aur.archlinux.org/packages/
play https://play.google.com/store/apps/details?id=
chrome https://chrome.google.com/webstore/detail/
manjaro https://wiki.manjaro.org/index.php?title=
wpzh https://zh.wikipedia.org/zh/
age https://www.agemys.net/detail/
bimi https://www.bimiacg4.net/bangumi/bi/
so https://stackoverflow.com/questions/
gh https://github.com/")

(let (val)
  (dolist (el (convert-inter-wikis my-org-abbrev-links) val)
    (pushnew! org-link-abbrev-alist
              (cons (nth 0 el) (nth 1 el)))
    ))

(setq delete-by-moving-to-trash t)


;; https://emacs.stackexchange.com/questions/47782/is-there-a-way-emacs-can-infer-is-running-on-wsl-windows-subsystem-for-linux
(when (string-match "-[Mm]icrosoft" operating-system-release)
  ;; WSL: WSL1 has "-Microsoft", WSL2 has "-microsoft-standard"
  ;; https://discourse.doomemacs.org/t/keeping-font-size-everywhere/2799
  (setq doom-font (font-spec :family "Source Code Pro" :size 20.0))
  )
;; set cjk font for unicode to fix ununified Chinese chars
(setq doom-unicode-font (font-spec :family "Noto Sans Mono CJK SC"))


(setq org-pandoc-import-dokuwiki-extensions '("dokuwiki" "txt"))

(use-package! org-pandoc-import :after org
              :custom
              (org-pandoc-import-global-args '("--wrap=none"))
              :config
              (org-pandoc-import-backend dokuwiki)
              ;; @TODO fix bug
              ;; (map! :leader :desc "Convert to OrgMode from DokuWiki" :n "n i d"
              ;;   #'my-current-buffer-as-dokuwiki-to-org)
              (map! :leader :desc "Convert to OrgMode" :n "n i i"
                    #'org-pandoc-import-to-org)
              )

;; TODO: remove this
(defun my-current-buffer-as-dokuwiki-to-org ()
  (org-pandoc-import-convert nil nil "dokuwiki" (buffer-file-name) '("txt") org-pandoc-import-dokuwiki-args org-pandoc-import-dokuwiki-filters nil nil))


(use-package! ox-pandoc :custom (org-pandoc-options '("--wrap=none")))

(use-package! org-download
  :after org
  :custom
  (org-download-image-dir (expand-file-name "images" my-roam-dir))
  :config
  (org-download-enable)
  (map!
   :map org-mode-map :leader :prefix "m i"
   :desc "paste image from clipboard" :n "p" #'org-download-clipboard
   :desc "get image from kill-ring" :n "y" #'org-download-yank
   :desc "delete image link and source file" :n "d" #'org-download-delete))

(use-package! org-transclusion
  :after org
  :init
  (map!
   :map global-map "<f12>" #'org-transclusion-add
   :leader
   :prefix "n"
   :desc "Org Transclusion Mode" "t" #'org-transclusion-mode))

(use-package! lsp-bridge
  :config
  (global-lsp-bridge-mode))

; (use-package! wallabag
;   :defer-incrementally t
;   :custom
;   (wallabag-host "https://wallabag")
;   (wallabag-username "gkzhb")
;   (wallabag-password ""))

(use-package! rime
  :custom
  (default-input-method "rime")
  (rime-show-candidate 'posframe)
  (rime-posframe-properties (list :font "Noto Sans Mono CJK SC")))
(use-package! format-all
  :config
  (map!
   :leader
   :prefix "b"
   :desc "Format current buffer" "f" #'format-all-buffer)
  (when (eq system-type 'darwin)
    ;; https://github.com/DogLooksGood/emacs-rime/issues/58 customize for doom ~/.emacs.d/librime/dist
    (setq rime-librime-root (expand-file-name "librime/dist" doom-emacs-dir))
    (setq trash-directory "~/.Trash")) )
