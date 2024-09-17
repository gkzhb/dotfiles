;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")
(defun my-is-termux () (getenv "TERMUX_VERSION"))

(setq doom-theme 'doom-one)
(after! doom-ui
  (menu-bar-mode -1))

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
  ;; (setq gptel-default-mode 'org-mode)
  (setq gptel-backend
        (gptel-make-openai "SiliconFlow" :models '("THUDM/glm-4-9b-chat") :host "api.siliconflow.cn" :protocol "https"
                           :key  "sk-xxxxx"))
  (setq gptel-model "THUDM/glm-4-9b-chat")
  (gptel-make-ollama "Local Ollama"             ;Any name of your choosing
    :host "localhost:11434"
    :stream t
    :models '("llama3:8b-instruct-q5_K_M" "yi:9b-chat-v1.5-q5_K_M" "qwen2" "phi3:14b-medium-128k-instruct-q5_K_M" "gemma2:9b-instruct-q5_K_M"))
  (map! :prefix ("C-c g" . "gptel")
        :desc "send to gptel" "g" #'gptel-send
        :desc "gptel menu" "m" #'gptel-menu))
(setq my-org-properties '("OBJECT_TYPE" "ZOTERO" "ROAM_REFS" "CAPTURED" "TECH_SOLUTION" "TECH_SOLUTION_BACKEND" "MEEGO" "PRD" "GIT_BRANCH" "GIT_REPO" "MR" "DOC"))
(after! org
  ;; modified based on doom org config
  (setq org-todo-keywords
        '((sequence
           "TODO(t)"  ; A task that needs doing & is ready to do
           "PROJ(p)"  ; A project, which usually contains other tasks
           "LOOP(r)"  ; A recurring task
           "STRT(a!)"  ; A task that is in progress
           "WAIT(w@/!)"  ; Something external is holding up this task
           "HOLD(h@/!)"  ; This task is paused/on hold because of me
           "IDEA(i)"  ; An unconfirmed and unapproved task or notion
           "|"
           "DONE(d!)"  ; Task successfully completed
           "CANCELLED(c@/!)" ; Task was cancelled
           "KILL(k!)") ; Task was cancelled, aborted, or is no longer applicable
          (sequence
           "[ ](T)"   ; A task that needs doing
           "[-](S)"   ; Task is in progress
           "[?](W)"   ; Task is being held up or paused
           "|"
           "[X](D)")  ; Task was completed
          (sequence ; Software engineer procedure
           "DESIGN(g!)"
           "DEV(e!)"
           "TEST(s!)"
           "MERGE(m!)"
           "DEPLOY(o!)")
          (sequence ; bugfix procedure
           "COMMIT(i!)"
           "VERIFY(v!)"
           "|"
           "FIXED(f!)")
          (sequence
           "|"
           "OKAY(o)"
           "YES(y)"
           "NO(n)"))
        org-todo-keyword-faces
        '(("[-]"  . +org-todo-active)
          ("STRT" . +org-todo-active)
          ("[?]"  . +org-todo-onhold)
          ("WAIT" . +org-todo-onhold)
          ("HOLD" . +org-todo-onhold)
          ("PROJ" . +org-todo-project)
          ("NO"   . +org-todo-cancel)
          ("KILL" . +org-todo-cancel)))
                                        ; set default tag list
  (setq org-tag-persistent-alist '(("work") ("topic") ("journal") ("project")
                                   ("fleet_node") ("ref_note") ("lit_node") ("main_card") ("bib_card") ("index_card")
                                   ("capture") ("byte") ("share")
                                   ("summary") ("plugin") ("zotero")
                                   ("wallabag") ("awesome")
                                   ("feat") ("bug") ("tech")))
  (setq org-edit-src-content-indentation 0)
  (map! :map org-mode-map :leader :prefix "l"
        :desc "" :n "o" #'+org/insert-item-below
        :desc "" :n "O" #'+org/insert-item-above)
  (setq org-default-properties (append org-default-properties my-org-properties))
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((python . t) (emacs-lisp . t) (jupyter . t))))
;; jupyter with org babel related
;;
;; (defun org-babel-edit-prep:python (babel-info)
;;   (setq-local buffer-file-name (->> babel-info caddr (alist-get :tangle)))
;;   (lsp))

;; resolve emacs-jupyter bug
(with-eval-after-load 'ob-jupyter
  (org-babel-jupyter-aliases-from-kernelspecs))

;; evil: set '_' as part of word
(add-hook! 'python-mode-hook (modify-syntax-entry ?_ "w"))

(use-package! code-cells
  :config
  (map! :map code-cells-mode-map
        :desc "eval python cell" "C-c C-c" 'code-cells-eval
        :desc "next python cell" :n "[ C" 'code-cells-backward-cell
        :desc "next python cell" :n "] C" 'code-cells-forward-cell
        )
  (add-hook 'python-mode-hook 'code-cells-mode-maybe))
;; (use-package! polymode
;;   :config
;;   (add-to-list 'polymode-run-these-before-change-functions-in-other-buffers 'lsp-before-change))
;; (use-package! poly-org)

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
(defun my-org-roam-files ()
  "Get org file list under Org Roam directory"
  (directory-files-recursively my-roam-dir "\\.org$"))
(defun my-refresh-org-agenda-files ()
  (interactive)
  (setq org-agenda-files
        (list org-directory my-roam-dir
              (file-name-concat my-roam-dir my-roam-dailies-dir))))
(defun my-calc-date-to-today (days)
  "Calculate the target date relative to today.
Return value is string that likes \"2024-07-21\" "
  (let* ((current-date (current-time))
         (future-date (time-add current-date (days-to-time days)))
         (formatted-date (format-time-string "%Y-%m-%d" future-date)))
    formatted-date))
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

(defun my/org-roam-backlink-ql ()
  "Search Org Roam backlinks with `org-roam-ql-search'"
  (interactive)
  ;; get node at point
  (let* ((node (org-roam-db-diagnose-node)) (id (org-roam-node-id node)) (node-title (org-roam-node-title node)))
    (progn (org-roam-ql-search
            ;; hide node itself in backlink results
            `(and (backlink-to ,(list 'id id)) (not ,(list 'id id))))
           (message "Showing backlink results for \"%s\"" node-title))))
(defun my/org-ql-search ()
  (interactive)
  (org-ql-search (my-org-roam-files)))

(setq my-roam-dailies-file-path (file-name-concat my-roam-dailies-dir "%<%Y-%m-%d>.org"))
(defun my-fix-org-super-agenda-map ()
  "fix evil keybindings
https://github.com/alphapapa/org-super-agenda/issues/50"
  (setq org-super-agenda-header-map evil-org-agenda-mode-map))
;; setup org roam
(use-package! org-roam
  :custom
  (org-roam-directory my-roam-dir)
  (org-roam-dailies-directory my-roam-dailies-dir)
  (org-roam-capture-templates
   '(("d" "default" entry "* %?" :target
      (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}
- tags :: ")
      :unnarrowed t)))
  (org-roam-dailies-capture-templates
   '(("d" "default" entry
      "* %?"
      :target (file+head "%<%Y-%m-%d>.org"
                         "#+title: %<%Y-%m-%d>\n"))
     ("r" "reference note" entry "* %? :ref_note:"
      :target (file+head "%<%Y-%m-%d>.org"
                         "#+title: %<%Y-%m-%d>\n"))
     ("f" "fleeting note" entry "* %? :fleet_note:"
      :target (file+head "%<%Y-%m-%d>.org"
                         "#+title: %<%Y-%m-%d>\n"))
     ("w" "work todo" entry "* TODO %?\nSCHEDULED: %t"
      :target (file+head+olp "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n" ("TODO %<%Y-%m-%d> 工作 :work:\nSCHEDULED: %t")))))
  (org-roam-capture-ref-templates
   '(("r" "ref" plain "%?" :target
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
  (map! :map org-mode-map :prefix "C-c r"  :desc "Insert Org Roam Node" "i" #'org-roam-node-insert
        :map org-mode-map :localleader (:prefix ("v" . "org-ql")
                                        :desc "Search org roam note refs at point" "r" #'my/org-roam-backlink-ql
                                        "s" #'org-ql-search
                                        "v" #'org-roam-ql-search
                                        :desc "Fix org super agenda evil map" "f" #'my-fix-org-super-agenda-map))
  (when (my-is-termux)
    (progn (setq org-roam-node-display-template "${doom-hierarchy} ${doom-tags:10}")
           (setq browse-url-browser-function 'browse-url-xdg-open))
    ))

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

(use-package! org-ql
  :config
  (map! :map org-ql-view-map :prefix ("C-c v" . "org-ql") "v" #'org-ql-view-dispatch)
  (map! :leader :prefix ("v" . "org views")
        "v" #'org-ql-view
        :desc "Refresh org agenda files" "r" #'my-refresh-org-agenda-files
        :desc "Fix org super agenda evil map" "f" #'my-fix-org-super-agenda-map))
(setq org-ql-views
      (list (cons "Overview: Agenda-like"
                  (list :buffers-files #'org-agenda-files
                        :query '(and (not (done))
                                     (or (habit)
                                         (deadline auto)
                                         (scheduled :to today)
                                         (ts-active :on today)))
                        :sort '(todo priority date)
                        :super-groups 'org-super-agenda-groups
                        :title "Agenda-like"))
            (cons "Overview: NEXT tasks"
                  (list :buffers-files #'org-agenda-files
                        :query '(todo "NEXT")
                        :sort '(date priority)
                        :super-groups 'org-super-agenda-groups
                        :title "Overview: NEXT tasks"))
            (cons "Calendar: Today"
                  (list :buffers-files #'org-agenda-files
                        :query '(ts-active :on today)
                        :title "Today"
                        :super-groups 'org-super-agenda-groups
                        :sort '(priority)))
            (cons "Calendar: This week"
                  (lambda ()
                    "Show items with an active timestamp during this calendar week."
                    (interactive)
                    (let* ((ts (ts-now))
                           (beg-of-week (->> ts
                                             (ts-adjust 'day (- (ts-dow (ts-now))))
                                             (ts-apply :hour 0 :minute 0 :second 0)))
                           (end-of-week (->> ts
                                             (ts-adjust 'day (- 6 (ts-dow (ts-now))))
                                             (ts-apply :hour 23 :minute 59 :second 59))))
                      (org-ql-search (org-agenda-files)
                        `(ts-active :from ,beg-of-week
                          :to ,end-of-week)
                        :title "This week"
                        :super-groups 'org-super-agenda-groups
                        :sort '(priority)))))
            (cons "Calendar: Next week"
                  (lambda ()
                    "Show items with an active timestamp during the next calendar week."
                    (interactive)
                    (let* ((ts (ts-adjust 'day 7 (ts-now)))
                           (beg-of-week (->> ts
                                             (ts-adjust 'day (- (ts-dow (ts-now))))
                                             (ts-apply :hour 0 :minute 0 :second 0)))
                           (end-of-week (->> ts
                                             (ts-adjust 'day (- 6 (ts-dow (ts-now))))
                                             (ts-apply :hour 23 :minute 59 :second 59))))
                      (org-ql-search (org-agenda-files)
                        `(ts-active :from ,beg-of-week
                          :to ,end-of-week)
                        :title "Next week"
                        :super-groups 'org-super-agenda-groups
                        :sort '(priority)))))
            (cons "Review: Recently timestamped" #'org-ql-view-recent-items)
            (cons (propertize "Review: Dangling tasks"
                              'help-echo "Tasks whose ancestor is done")
                  (list :buffers-files #'org-agenda-files
                        :query '(and (todo)
                                     (ancestors (done)))
                        :title (propertize "Review: Dangling tasks"
                                           'help-echo "Tasks whose ancestor is done")
                        :sort '(todo priority date)
                        :super-groups '((:auto-parent t))))
            (cons (propertize "Review: Stale tasks"
                              'help-echo "Tasks without a timestamp in the past 2 weeks")
                  (list :buffers-files #'org-agenda-files
                        :query '(and (todo)
                                     (not (ts :from -14)))
                        :title (propertize "Review: Stale tasks"
                                           'help-echo "Tasks without a timestamp in the past 2 weeks")
                        :sort '(todo priority date)
                        :super-groups '((:auto-parent t))))
            (cons (propertize "Review: Stuck projects"
                              'help-echo "Tasks with sub-tasks but no NEXT sub-tasks")
                  (list :buffers-files #'org-agenda-files
                        :query '(and (todo)
                                     (descendants (todo))
                                     (not (descendants (todo "NEXT"))))
                        :title (propertize "Review: Stuck projects"
                                           'help-echo "Tasks with sub-tasks but no NEXT sub-tasks")
                        :sort '(date priority)
                        :super-groups 'org-super-agenda-groups))
            (cons "Work items" (list :buffers-files #'org-agenda-files
                                     :query '(and (not (done)) (todo "TODO" "STRT") (tags "work"))
                                     :title "工作事项清单"
                                     :sort '(todo priority date)
                                     :super-groups '((:auto-parent t))))
            ))

(use-package! helm-org-ql)

(use-package! org-roam-ql
  :after (org-roam))
(use-package! org-roam-ql-ql
  :after (org-ql org-roam-ql)
  :config
  (org-roam-ql-ql-init))

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
  :after (:all org-agenda evil evil-org-agenda)
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
          ))
  (my-fix-org-super-agenda-map))

(use-package! org-hyperscheduler)

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

;; lsp related
(use-package! lsp-jedi)
