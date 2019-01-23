;; ignore case for completions
(setq completion-ignore-case  t)

;; good colors for Linux
(if (eq system-type 'gnu/linux)
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(font-lock-comment-face ((t (:foreground "cyan"))))
 '(font-lock-function-name-face ((t (:foreground "color-27"))))
 '(font-lock-string-face ((t (:foreground "magenta"))))
 '(minibuffer-prompt ((t (:foreground "blue")))))
)