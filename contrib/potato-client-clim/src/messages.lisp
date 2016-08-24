(in-package :potato-client-clim)

(defclass message ()
  ((id           :type string
                 :initarg :id
                 :reader message/id)
   (channel      :type string
                 :initarg :channel
                 :reader message/channel)
   (from         :type string
                 :initarg :from
                 :reader message/from)
   (from-name    :type string
                 :initarg :from-name
                 :reader message/from-name)
   (created-date :type local-time
                 :initarg :created-date
                 :reader message/created-date)
   (text         :type t
                 :initarg :text
                 :reader message/text)))

(defmethod print-object ((obj message) stream)
  (print-unreadable-object (obj stream :type t :identity t)
    (format stream "ID ~s TEXT ~s"
            (slot-value obj 'id)
            (slot-value obj 'text))))

(defclass channel-content-view (clim:view)
  ())

(defclass set-element ()
  ((elements :type list
             :initarg :elements
             :reader set-element/elements)))

(defmethod print-object ((obj set-element) stream)
  (print-unreadable-object (obj stream :type t :identity nil)
    (format stream "~s" (slot-value obj 'elements))))

(defclass text-element ()
  ())

(defclass formatted-element (text-element)
  ((text :type t
         :initarg :text
         :reader formatted-element/text)))

(defmethod print-object ((obj formatted-element) stream)
  (print-unreadable-object (obj stream :type t :identity nil)
    (format stream "TEXT ~s" (slot-value obj 'text))))

(defclass paragraph-element (formatted-element) ())
(defclass bold-element (formatted-element) ())
(defclass italics-element (formatted-element) ())
(defclass code-element (formatted-element) ())
(defclass newline-element (text-element) ())

(defun parse-text-content (content)
  (etypecase content
    (string content)
    (list (make-instance 'set-element :elements (mapcar #'parse-text-content content)))
    (st-json:jso (parse-text-part content))))

(defun parse-text-part (content)
  (let ((type (st-json:getjso "type" content)))
    (labels ((make-element (name)
               (make-instance name :text (parse-text-content (st-json:getjso "e" content)))))
      (string-case:string-case (type)
        ("p" (make-element 'paragraph-element))
        ("b" (make-element 'bold-element))
        ("i" (make-element 'italics-element))
        ("code" (make-element 'code-element))
        ("newline" (make-instance 'newline-element))
        (t (format nil "[unknown type:~a]" type))))))

(clim:define-presentation-method clim:present (obj (type message) stream (view channel-content-view) &key)
  (format stream "~a - " (message/from-name obj))
  (clim:present (message/text obj)))

(clim:define-presentation-method clim:present (obj (type formatted-element) stream (view channel-content-view) &key)
  (clim:present (formatted-element/text obj)))

(clim:define-presentation-method clim:present (obj (type bold-element) stream (view channel-content-view) &key)
  (clim:with-text-style (stream (clim:make-text-style nil :bold nil))
    (let ((v (formatted-element/text obj)))
      (clim:present v (clim:presentation-type-of v) :stream stream))))

(clim:define-presentation-method clim:present (obj (type italics-element) stream (view channel-content-view) &key)
  (clim:with-text-style (stream (clim:make-text-style nil :italic nil))
    (let ((v (formatted-element/text obj)))
      (clim:present v (clim:presentation-type-of v) :stream stream))))

(clim:define-presentation-method clim:present (obj (type code-element) stream (view channel-content-view) &key)
  (clim:with-text-style (stream (clim:make-text-style :fix nil nil))
    (let ((v (formatted-element/text obj)))
      (clim:present v (clim:presentation-type-of v) :stream stream))))

(clim:define-presentation-method clim:present (obj (type paragraph-element) stream (view channel-content-view) &key)
  (clim:present (formatted-element/text obj))
  (format stream "~%"))

(clim:define-presentation-method clim:present (obj (type string) stream (view channel-content-view) &key)
  (format stream "~a" obj))

(clim:define-presentation-method clim:present (obj (type set-element) stream (view channel-content-view) &key)
  (dolist (element (set-element/elements obj))
    (clim:present element)))
