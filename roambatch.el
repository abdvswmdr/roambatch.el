;;; roambatch.el --- Batch insert multiple org-roam nodes with Helm -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Abdulswamad Rama <github.com/abdvswmdr>
;; Author: Abdulswamad Rama
;; URL: http://github.com/abdvswmdr/roambatch.el
;; Created: 2025
;; Version: 0.1.0
;; Keywords: outlines convenience hypermedia org-roam helm
;; Package-Requires: ((emacs "27.1") (org-roam "2.0") (helm "3.0"))
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is NOT part of GNU Emacs.
;;
;;; Commentary:
;;
;; This function provides the ability to insert mulitiple org-roam nodes from within Emacs

;;; Code:
(require 'org-roam)
(require 'helm)

(defun roambatch--mark-and-move-forward ()
  "Mark current candidate and move forward (stay in flow with navigation)."
  (interactive)
  (helm-toggle-visible-mark-forward))

;;;###autoload
(defun roambatch ()
  "Batch-insert multiple org-roam node links using Helm multi-selection.

Mark multiple nodes with M-SPC and insert all at once with RET.
Each link is inserted on its own line.

Keybindings in Helm buffer:
  - M-SPC: mark/unmark current node
  - ,/.: navigate down/up between results
  - C-;: mark all visible nodes
  - RET: insert all marked nodes"
  (interactive)
  (unless (require 'org-roam nil t)
    (user-error "Package org-roam is not available.  Please install it first"))
  (unless (require 'helm nil t)
    (user-error "Package helm is not available.  Please install it first"))

  ;; Get all org-roam nodes
  (let* ((nodes (org-roam-node-list))
         (node-hash (make-hash-table :test 'equal))
         (candidates (mapcar (lambda (node)
                               (let ((display (org-roam-node-title node)))
                                 (puthash display node node-hash)
                                 display))
                             nodes)))

    ;; Variable to capture marked items from Helm
    (let ((marked-items '()))
      ;; Create a custom Helm source with action that captures marked candidates
      (let ((helm-source (helm-make-source "Org-Roam Nodes" 'helm-source-sync
                           :candidates candidates
                           :action (list (cons "Insert All Marked"
                                               (lambda (candidate)
						 ;; Get marked candidates while Helm is still open
						 (setq marked-items (or (helm-marked-candidates)
									(list candidate)))))))))

        ;; Create custom keymap for navigation and marking all
        (let ((helm-map (copy-keymap helm-map)))
          ;; Use M-SPC to mark/unmark and move forward
          (define-key helm-map (kbd "M-SPC") 'roambatch--mark-and-move-forward)

          ;; Use C-; to mark all visible nodes
          (define-key helm-map (kbd "C-;") 'helm-mark-all)

          ;; Use , and . for navigation (don't interfere with search input)
          (define-key helm-map (kbd ",") 'helm-next-line)
          (define-key helm-map (kbd ".") 'helm-previous-line)

          ;; Use helm to select multiple nodes
          (helm :sources helm-source
                :prompt "Mark with M-SPC, , and . navigate, C-; mark all: "
                :keymap helm-map
                :allow-nest t
                :buffer "*helm org-roam batch*")

          ;; Insert links for all marked nodes
          (when marked-items
            (dolist (display marked-items)
              (let ((node (gethash display node-hash)))
                (if node
                    ;; Create org-mode link using org-link-make-string
                    (progn
                      (insert (org-link-make-string (concat "id:" (org-roam-node-id node))
                                                    (org-roam-node-title node)))
                      (insert "\n"))
                  (message "Node not found: %s" display))))))))))

(provide 'roambatch)
;;; roambatch.el ends here
