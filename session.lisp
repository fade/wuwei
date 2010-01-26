(in-package :wu)

(export '(with-session with-http-response-and-body))

#|
Session management, for now, largely copied from our modified BioBike
|#

(defun cookie-value (req name)
  (assocdr name (get-cookie-values req) :test #'equal))

(defun cookie-package (req)
  (cookie-value req "Biobike-pkg"))

;;; Note: has to be INSIDE with-http-response-and-body or equiv
(defmacro with-session ((req ent) &body body)
  `(let* ((package-name (cookie-package ,req))
	  (*sessionid* (and package-name (keywordize package-name))))
     (if (and *sessionid*
	      (get *sessionid* :username))
	 ;; +++ remaining link to wb world
	 (wb::with-protected-globals-bound *sessionid*
	   ,@body)
	 ;; else
	 (need-to-login-response ,req ,ent)
	 )))

(defmacro session-wrap ((req ent session) &body body)
  (if session
      `(with-session (,req ,ent)
           ,@body)
      `(progn ,@body)))

(defmacro with-http-response-and-body ((req ent &key (whole-page nil) (content-type "text/html") session) &body body)
  #.(doc
     "Combines WITH-HTTP-RESPONSE and WITH-HTTP-BODY, which is the"
     "normal way we use those macros.  In doing this we also gain in that"
     "Lispworks will now indent this new macro properly, whereas for some"
     "reason it won't indent WITH-HTTP-RESPONSE or WITH-HTTP-BODY sanely.")
  `(session-wrap (,req ,ent ,session)
    ,(if whole-page
        `(with-http-response (,req ,ent :content-type ,content-type)
           (with-http-body (,req ,ent)
             (html (:html ,@body))))
        `(with-http-response (,req ,ent :content-type ,content-type)
           (with-http-body (,req ,ent)
             ,@body))
        )))


