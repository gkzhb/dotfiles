;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

(setq doom-theme 'doom-one)
(menu-bar-mode -1)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
;; (setq display-line-numbers-type 'relative)
;;
(setq display-line-numbers-type 'visual)

(setq shell-file-name (executable-find "bash"))

;; List of suggestions from which-key is partially covered by status line
;; https://github.com/doomemacs/doomemacs/issues/5622
(setq which-key-allow-imprecise-window-fit nil)

(after! evil
  (setq evil-auto-indent nil))
(use-package! evil-snipe
  :custom
  (evil-snipe-scope 'buffer))

(use-package! gptel
  :config
  ;; (setq! gptel-api-key "your key")
  ;; (setq gptel-default-mode 'org-mode)
  (setq gptel-backend (gptel-make-ollama "Devbox Ollama"             ;Any name of your choosing
                        :host "byte.gkzhb.top:11434"
                        :stream t
                        :models '("llama3:8b-instruct-q5_K_M" "qwen:7b-chat-v1.5-q5_K_M" "mistral:7b-instruct-v0.2-q5_K_M"))
        )
  (gptel-make-ollama "Local Ollama"             ;Any name of your choosing
    :host "localhost:11434"
    :stream t
    :models '("llama3:8b-instruct-q5_K_M"))
  )
(setq my-org-properties '("TECH_SOLUTION" "TECH_SOLUTION_BACKEND" "MEEGO" "PRD" "GIT_BRANCH" "GIT_REPO" "MR" "DOC"))
(after! org
  (map! :map org-mode-map :leader :prefix "l"
        :desc "" :n "o" #'+org/insert-item-below
        :desc "" :n "O" #'+org/insert-item-above
        )
  (setq org-default-properties (append org-default-properties my-org-properties)
        )
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((python . t) (emacs-lisp . t)
     )))
(defun org-babel-edit-prep:python (babel-info)
  (setq-local buffer-file-name (->> babel-info caddr (alist-get :tangle)))
  (lsp))

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
      (list org-directory my-roam-dir
            (file-name-concat my-roam-dir my-roam-dailies-dir)))
(defun zhb-refresh-org-agenda-files ()
  (interactive)
  (setq org-agenda-files
        (list org-directory my-roam-dir
              (file-name-concat my-roam-dir my-roam-dailies-dir))))
;; (setq org-tag-persistent-alist '(("work" . "w") ("capture" . "c") ("topic" . "t") ("byte" . "b") ("journal" . "j")))
;; set header https://org-roam.discourse.group/t/configure-deft-title-stripping-to-hide-org-roam-template-headers/478
(use-package! deft
  :after org
  :custom
  (deft-directory my-roam-dir)
  (deft-recursive t)
  (deft-use-filter-string-for-filename t)
  (deft-default-extension "org")
  :config
  (defun cf/deft-parse-title (file contents)
    "Parse the given FILE and CONTENTS and determine the title.
    If `deft-use-filename-as-title' is nil, the title is taken to
    be the first non-empty line of the FILE.  Else the base name of the FILE is
    used as title."
    (let ((begin (string-match "^#\\+[tT][iI][tT][lL][eE]: .*$" contents)))
      (if begin
          (string-trim (substring contents begin (match-end 0)) "#\\+[tT][iI][tT][lL][eE]: *" "[\n\t ]+")
        (deft-base-filename file))))
  (advice-add 'deft-parse-title :override #'cf/deft-parse-title)
  (setq deft-strip-summary-regexp
        (concat "\\("
                "[\n\t]" ;; blank
                "\\|^#\\+[[:alpha:]_]+:.*$" ;; org-mode metadata
                "\\|^:PROPERTIES:\n\\(.+\n\\)+:END:\n" ;; org-roam ID
                "\\|\\[\\[\\(.*\\]\\)" ;; any link
                "\\)")))

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
     ("d" "daily entry" entry "* [[${ref}][${title}]] :capture:
:PROPERTIES:
:CAPTURED: %U
:ROAM_REFS: ${ref}
:END:
- tags :: %?

${body}
" :target
(file+head (lambda() my-roam-dailies-file-path) "#+title: %<%Y-%m-%d>
" ))))
  :config
  (org-roam-setup)
  (org-roam-db-autosync-mode)
  (map! :map org-mode-map :prefix "C-c r"  :desc "Insert Org Roam Node" "i" #'org-roam-node-insert))

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

(map! :after org-roam :leader :desc "Search Org Roam notes" :n "s n"
      #'+default/org-roam-search)

(use-package! org-roam-timestamps
  :after org-roam
  :config (org-roam-timestamps-mode))

(use-package! org-ql)
(use-package! helm-org-ql)
(use-package! org-roam-ql
  :after (org-roam)
  )

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
(setq doom-symbol-font (font-spec :family "Noto Sans Mono CJK SC"))

(setq org-pandoc-import-dokuwiki-extensions '("dokuwiki" "txt"))

(use-package! org
  :config
  (org-link-set-parameters "zotero" :follow
                           (lambda (zpath)
                             (browse-url
                              ;; we get the "zotero:"-less url, so we put it back.
                              (format "zotero:%s" zpath))))
  )
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

(use-package! org-super-agenda
  :after org-agenda
  :config
  (org-super-agenda-mode)
  (setq org-super-agenda-groups
        '(
          (:name "Work"
           :tag "work")
          (:name "High Priority"
           :priority>= "B")
          (:name "Today"
           :time-grid t
           :todo "TODO")
          )))

(use-package! org-transclusion
  :after org
  :init
  (map!
   :map global-map "<f12>" #'org-transclusion-add
   :leader
   :prefix "n"
   :desc "Org Transclusion Mode" "t" #'org-transclusion-mode))

(use-package! org-web-tools
  :config
  (defun org-web-tools--get-url (url)
    "Return content for URL as string.
This uses `url-retrieve-synchronously' to make a request with the
URL, then returns the response body.  Since that function returns
the entire response, including headers, we must remove the
headers ourselves."
    (let* ((response-buffer (url-retrieve-synchronously url))
           (encoded-html (with-current-buffer response-buffer
                           ;; Skip HTTP headers.
                           ;; FIXME: Byte-compiling says that `url-http-end-of-headers' is a free
                           ;; variable, which seems to be because it's not declared by url.el with
                           ;; `defvar'.  Yet this seems to work fine...
                           (delete-region (point-min) url-http-end-of-headers)
                           (buffer-string))))
      ;; NOTE: Be careful to kill the buffer, because `url' doesn't close it automatically.
      (kill-buffer response-buffer)
      (with-temp-buffer
        ;; For some reason, running `decode-coding-region' in the
        ;; response buffer has no effect, so we have to do it in a
        ;; temp buffer.
        (insert encoded-html)
        (condition-case nil
            ;; Fix undecoded text
            (decode-coding-region (point-min) (point-max) 'utf-8)
          (coding-system-error nil))
        (buffer-string)))))

(use-package! ob-mermaid
  :custom
  (ob-mermaid-cli-path (executable-find "mmdc")))

(use-package! mermaid-ts-mode)

;; (use-package! lsp-bridge
;;   :config
;;   (global-lsp-bridge-mode))

(use-package! rime
  :custom
  (default-input-method "rime")
  (rime-show-candidate 'posframe)
  (rime-posframe-properties (list :font "Noto Sans CJK SC" :internal-border-width 5)))
(use-package! format-all
  :config
  (map!
   :leader
   :prefix "b"
   :desc "Format current buffer" "f" #'format-all-buffer)
  (when (eq system-type 'darwin)
    ;; https://github.com/DogLooksGood/emacs-rime/issues/58 customize for doom ~/.emacs.d/librime/dist
    (setq rime-librime-root (expand-file-name "librime/dist" doom-emacs-dir))
    (setq rime-emacs-module-header-root "/opt/homebrew/include")
    (setq trash-directory "~/.Trash")) )

(use-package! vulpea
  :hook ((org-roam-db-autosync-mode . vulpea-db-autosync-enable)))

;; Python
(defun projectile-pyenv-mode-set ()
  "Set pyenv version matching project name."
  (let ((project (projectile-project-name)))
    (if (member project (pyenv-mode-versions))
        (pyenv-mode-set project)
      (pyenv-mode-unset))))

(use-package! projectile
  :config
  (add-hook 'projectile-after-switch-project-hook 'projectile-pyenv-mode-set))

;; optimize org agenda performance
;; https://d12frosted.io/posts/2021-01-16-task-management-with-roam-vol5.html
;; (defun vulpea-project-p ()
;;   "Return non-nil if current buffer has any todo entry.

;; TODO entries marked as done are ignored, meaning the this
;; function returns nil if current buffer contains only completed
;; tasks."
;;   (seq-find                                 ; (3)
;;    (lambda (type)
;;      (eq type 'todo))
;;    (org-element-map                         ; (2)
;;        (org-element-parse-buffer 'headline) ; (1)
;;        'headline
;;      (lambda (h)
;;        (org-element-property :todo-type h)))))

;; (defun vulpea-project-update-tag ()
;;     "Update PROJECT tag in the current buffer."
;;     (when (and (not (active-minibuffer-window))
;;                (vulpea-buffer-p))
;;       (save-excursion
;;         (goto-char (point-min))
;;         (let* ((tags (vulpea-buffer-tags-get))
;;                (original-tags tags))
;;           (if (vulpea-project-p)
;;               (setq tags (cons "project" tags))
;;             (setq tags (remove "project" tags)))

;;           ;; cleanup duplicates
;;           (setq tags (seq-uniq tags))

;;           ;; update tags if changed
;;           (when (or (seq-difference tags original-tags)
;;                     (seq-difference original-tags tags))
;;             (apply #'vulpea-buffer-tags-set tags))))))

;; (defun vulpea-buffer-p ()
;;   "Return non-nil if the currently visited buffer is a note."
;;   (and buffer-file-name
;;        (string-prefix-p
;;         (expand-file-name (file-name-as-directory org-roam-directory))
;;         (file-name-directory buffer-file-name))))

;; (defun vulpea-project-files ()
;;     "Return a list of note files containing 'project' tag." ;
;;     (seq-uniq
;;      (seq-map
;;       #'car
;;       (org-roam-db-query
;;        [:select [nodes:file]
;;         :from tags
;;         :left-join nodes
;;         :on (= tags:node-id nodes:id)
;;         :where (like tag (quote "%\"project\"%"))]))))

;; (defun vulpea-agenda-files-update (&rest _)
;;   "Update the value of `org-agenda-files'."
;;   (setq org-agenda-files (vulpea-project-files)))

;; (add-hook 'find-file-hook #'vulpea-project-update-tag)
;; (add-hook 'before-save-hook #'vulpea-project-update-tag)

;; (advice-add 'org-agenda :before #'vulpea-agenda-files-update)
;; (advice-add 'org-todo-list :before #'vulpea-agenda-files-update)
