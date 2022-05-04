;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Pre gopls/lsp-mode/go-mode setup
;;; This section installs use-package from melpa if it isn't
;;; already installed. You can skip this if you already have use-package

;; enable melpa if it isn't enabled
(require 'package)
(when (not (assoc "melpa" package-archives))
  (setq package-archives (append '(("stable" . "https://stable.melpa.org/packages/")) package-archives))
  (setq package-archives (append '(("melpa" . "https://melpa.org/packages/")) package-archives))
  (setq package-archives (append '(("gnu" . "https://elpa.gnu.org/packages/")) package-archives)))
(package-initialize)

(add-to-list 'load-path "~/.emacs.d/lisp/")

;; refresh package list if it is not already available
(when (not package-archive-contents) (package-refresh-contents))

;; install use-package if it isn't already installed
(when (not (package-installed-p 'use-package))
  (package-install 'use-package))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Install and configure pacakges

(setq fit-window-to-buffer-horizontally t)

(add-hook 'after-init-hook 'global-flycheck-mode)
(add-hook 'after-init-hook 'global-company-mode)
(eval-after-load 'flycheck
  '(add-hook 'flycheck-mode-hook #'flycheck-golangci-lint-setup))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(inhibit-startup-screen t)
 '(lsp-ui-imenu-enable t)
 '(package-selected-packages
   '(treemacs dap-mode flycheck-golangci-lint projectile flx-ido yasnippet use-package lsp-ui go-mode flycheck company-lsp))
 '(tool-bar-mode nil))

;; use golangci
(use-package flycheck-golangci-lint
  :ensure t)

;; optional, provides snippets for method signature completion
(use-package yasnippet
  :ensure t)

(use-package lsp-mode
  :ensure t
  ;; uncomment to enable gopls http debug server
  ;; :custom (lsp-gopls-server-args '("-debug" "127.0.0.1:0"))
  :commands (lsp lsp-deferred)
  :hook (go-mode . lsp-deferred)
  :config (progn
            ;; use flycheck, not flymake
            (setq lsp-prefer-flymake nil)
	    ;;(setq lsp-trace nil)
	    (setq lsp-print-performance nil)
	    (setq lsp-log-io nil))
  )

;; Set up before-save hooks to format buffer and add/delete imports.
;; Make sure you don't have other gofmt/goimports hooks enabled.
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))
(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

;; debug
;;(setq lsp-log-io t)


;; optional - provides fancy overlay information
;; https://ladicle.com/post/config/
(use-package lsp-ui
  :ensure t
  :after(lsp-mode)
  :commands lsp-ui-mode
  :config (progn
            ;; disable inline documentation
            (setq lsp-ui-sideline-enable nil)
            ;; disable showing docs on hover at the top of the window
            (setq lsp-ui-doc-enable nil)
	    (setq lsp-ui-imenu-enable t)
	    (setq lsp-ui-imenu-kind-position 'top))
  )


(use-package company
  :ensure t
  :config (progn
            ;; don't add any dely before trying to complete thing being typed
            ;; the call/response to gopls is asynchronous so this should have little
            ;; to no affect on edit latency
            (setq company-idle-delay 0)
            ;; start completing after a single character instead of 3
            (setq company-minimum-prefix-length 2)
            ;; align fields in completions
            (setq company-tooltip-align-annotations t)
            )
  )

;; optional package to get the error squiggles as you edit
(use-package flycheck
  :ensure t)

;; if you use company-mode for completion (otherwise, complete-at-point works out of the box):
(use-package company-lsp
  :ensure t
  ;;:after(company lsp-mode)
  :commands company-lsp)

;;(use-package go-mode
;;  :ensure t
;;  :bind (
         ;; If you want to switch existing go-mode bindings to use lsp-mode/gopls instead
         ;; uncomment the following lines
;;         ("C-c C-j" .  xref-find-definitions)
;;         ("C-c C-d" .  xref-pop-marker-stack)
;;         ;; ("C-c C-d" . lsp-describe-thing-at-point)
;;         )
;;  :hook ((go-mode . lsp-deferred)
;;         (before-save . lsp-format-buffer)
;;         (before-save . lsp-organize-imports)))

(use-package use-package-hydra
  :ensure t)

;; go hydra
(use-package hydra
  :ensure t
  :config
  (require 'hydra)
  (require 'dap-mode)
  (require 'dap-ui)
  ;;:commands (ace-flyspell-setup)
  :bind
  ;;("M-s" . hydra-go/body)
  :init
  (add-hook 'dap-stopped-hook
          (lambda (arg) (call-interactively #'hydra-go/body)))
  :hydra (hydra-go (:color pink :hint nil :foreign-keys run)
  "
   _n_: Next       _c_: Continue _g_: goroutines      _i_: break log
   _s_: Step in    _o_: Step out _k_: break condition _h_: break hit condition
   _Q_: Disconnect _q_: quit     _l_: locals
   "
	     ("n" dap-next)
	     ("c" dap-continue)
	     ("s" dap-step-in)
	     ("o" dap-step-out)
	     ("g" dap-ui-sessions)
	     ("l" dap-ui-locals)
	     ("e" dap-eval-thing-at-point)
	     ("h" dap-breakpoint-hit-condition)
	     ("k" dap-breakpoint-condition)
	     ("i" dap-breakpoint-log-message)
	     ("q" nil "quit" :color blue)
	     ("Q" dap-disconnect :color red)))

;; DAP
(use-package dap-mode
  ;;:custom
  ;;(dap-go-debug-program `("node" "~/extension/out/src/debugAdapter/goDebug.js"))
  :config
  (dap-mode 1)
  (setq dap-print-io t)
  ;;(setq fit-window-to-buffer-horizontally t)
  ;;(setq window-resize-pixelwise t)
  (require 'dap-hydra)
  ;; old version 
  ;;  (require 'dap-go)		; download and expand vscode-go-extenstion to the =~/.extensions/go=
  ;;  (dap-go-setup)
  ;; new version
  (require 'dap-dlv-go)
	     
  (use-package dap-ui
    :ensure nil
    :config
    (dap-ui-mode 1)
    )
  )


(add-hook 'dap-stopped-hook
          (lambda (arg) (call-interactively #'dap-hydra)))


(provide 'gopls-config)
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )



;;; .emacs ends here
