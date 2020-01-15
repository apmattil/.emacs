;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Pre gopls/lsp-mode/go-mode setup
;;; This section installs use-package from melpa if it isn't
;;; already installed. You can skip this if you already have use-package

;; enable melpa if it isn't enabled
(require 'package)
(when (not (assoc "melpa" package-archives))
  (setq package-archives (append '(("melpa" . "https://melpa.org/packages/")) package-archives)))
(package-initialize)

;; refresh package list if it is not already available
(when (not package-archive-contents) (package-refresh-contents))

;; install use-package if it isn't already installed
(when (not (package-installed-p 'use-package))
  (package-install 'use-package))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Install and configure pacakges

(add-hook 'after-init-hook 'global-flycheck-mode)
(add-hook 'after-init-hook 'global-company-mode)
(eval-after-load 'flycheck
  '(add-hook 'flycheck-mode-hook #'flycheck-golangci-lint-setup))

;; disable top buttons
(tool-bar-mode -1)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(diff-switches "-u")
 '(inhibit-startup-screen t)
 '(package-selected-packages
   '(company-lsp company lsp-ui lsp-java dap-mode magit-gerrit magit ## flycheck-golangci-lint golint go-dlv go-mode neotree guru-mode go-projectile go-complete go-autocomplete flymake-go exec-path-from-shell)))

;; use golangci
(use-package flycheck-golangci-lint
             :ensure t)

;; optional, provides snippets for method signature completion
;;;(use-package yasnippet
;;;             :ensure t)

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

;; go mode
(use-package go-mode
  :ensure t
  :init
  :bind
  ("M-p" . 'compile)
  ("M-1" . 'next-error)
  ("M-2" . 'previous-error)
  :config
  (defun my-go-mode-hook ()
    (if (not (string-match "go" compile-command))   ; set compile command default
	(set (make-local-variable 'compile-command)
             "go build -v && go test -v && go vet"))
    )
  (add-hook 'go-mode-hook 'my-go-mode-hook)
  )
;; :bind (
      ;; If you want to switch existing go-mode bindings to use lsp-mode/gopls instead
;; uncomment the following lines
;; ("C-c C-j" .  xref-find-definitions)
;;  ("C-c C-d" .  xref-pop-marker-stack)
;; ;; ("C-c C-d" . lsp-describe-thing-at-point)
;; )
;; :hook ((go-mode . lsp-deferred)
;;  (before-save . lsp-format-buffer)
;;  (before-save . lsp-organize-imports)))


;;Smaller compilation buffer
(setq compilation-window-height 14)
(defun my-compilation-hook ()
  (when (not (get-buffer-window "*compilation*"))
    (save-selected-window
      (save-excursion
        (let* ((w (split-window-vertically))
               (h (window-height w)))
          (select-window w)
          (switch-to-buffer "*compilation*")
          (shrink-window (- h compilation-window-height)))))))
(add-hook 'compilation-mode-hook 'my-compilation-hook)


;; DAP
(use-package dap-mode
             ;;:custom
             ;;(dap-go-debug-program `("node" "~/extension/out/src/debugAdapter/goDebug.js"))
             :config
             (dap-mode 1)
             (setq dap-print-io nil)
             (require 'dap-hydra)
             (require 'dap-go)		; download and expand vscode-go-extenstion to the =~/.extensions/go=
             (dap-go-setup)
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
