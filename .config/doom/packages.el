;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; To install a package with Doom you must declare them here and run 'doom sync'
;; on the command line, then restart Emacs for the changes to take effect -- or
;; use 'M-x doom/reload'.


;; To install SOME-PACKAGE from MELPA, ELPA or emacsmirror:
                                        ;(package! some-package)

;; To install a package directly from a remote git repo, you must specify a
;; `:recipe'. You'll find documentation on what `:recipe' accepts here:
;; https://github.com/radian-software/straight.el#the-recipe-format
                                        ;(package! another-package
                                        ;  :recipe (:host github :repo "username/repo"))

;; If the package you are trying to install does not contain a PACKAGENAME.el
;; file, or is located in a subdirectory of the repo, you'll need to specify
;; `:files' in the `:recipe':
                                        ;(package! this-package
                                        ;  :recipe (:host github :repo "username/repo"
                                        ;           :files ("some-file.el" "src/lisp/*.el")))

;; If you'd like to disable a package included with Doom, you can do so here
;; with the `:disable' property:
                                        ;(package! builtin-package :disable t)

;; You can override the recipe of a built in package without having to specify
;; all the properties for `:recipe'. These will inherit the rest of its recipe
;; from Doom or MELPA/ELPA/Emacsmirror:
                                        ;(package! builtin-package :recipe (:nonrecursive t))
                                        ;(package! builtin-package-2 :recipe (:repo "myfork/package"))

;; Specify a `:branch' to install a package from a particular branch or tag.
;; This is required for some packages whose default branch isn't 'master' (which
;; our package manager can't deal with; see radian-software/straight.el#279)
                                        ;(package! builtin-package :recipe (:branch "develop"))

;; Use `:pin' to specify a particular commit to install.
                                        ;(package! builtin-package :pin "1a2b3c4d5e")

(package! request)
(package! gptel)
(package! aider :recipe (:host github :repo "tninja/aider.el" :files ("*.el")))
(package! org-ql)
(package! doct)
(package! doct-org-roam
  :recipe (:type git
           :repo "https://gist.github.com/f9b21eeea7d7c9123dc400a30599d50d.git"
           :files ("*.el")))
(package! helm-org-ql)
(package! org-super-agenda)
(package! org-hyperscheduler
  :recipe (:host github
           :repo "dmitrym0/org-hyperscheduler"
           :files ("*")))
(package! vulpea) ;; enhance org-roam
(package! org-roam-timestamps)
(package! org-roam-ql)
(package! org-roam-ql-ql)
(package! org-pandoc-import
  :recipe (:host github
           :repo "tecosaur/org-pandoc-import"
           :files ("*.el" "filters" "preprocessors")))
;; (package! calfw
;;   :recipe (:host github
;;            :repo "haji-ali/emacs-calfw"
;;            :files ("*.el")))
(package! ox-pandoc)
(package! org-download)
(package! org-transclusion)
(package! org-web-tools)
(package! org-appear)
(package! ob-mermaid)
(package! mermaid-ts-mode)
(package! format-all)
(package! rime)
(package! code-cells)
(package! lsp-jedi)
(package! uv-mode)

;; plenty of bugs in org mode, not usable
;; (package! polymode)
;; (package! poly-org)

;; (package! lsp-bridge :recipe (:host github :repo "manateelazycat/lsp-bridge" :files ("*" "acm/*")))
(package! wallabag
  :recipe (:host github
           :repo "chenyanming/wallabag.el"
           :files ("*.el" "*.alist" "*.css")))

(package! ai-code-interface
  :recipe (:host github :repo "tninja/ai-code-interface.el" ;; :branch "copilot/add-opencode-support" 
                 :files ("*.el")))

;; Doom's packages are pinned to a specific commit and updated from release to
;; release. The `unpin!' macro allows you to unpin single packages...
                                        ;(unpin! pinned-package)
;; ...or multiple packages
                                        ;(unpin! pinned-package another-pinned-package)
;; ...Or *all* packages (NOT RECOMMENDED; will likely break things)
                                        ;(unpin! t)
