;;; Copyright (c) 2015, Georg Bartels <georg.bartels@cs.uni-bremen.de>
;;; All rights reserved.
;;;
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions are met:
;;;
;;; * Redistributions of source code must retain the above copyright
;;; notice, this list of conditions and the following disclaimer.
;;; * Redistributions in binary form must reproduce the above copyright
;;; notice, this list of conditions and the following disclaimer in the
;;; documentation and/or other materials provided with the distribution.
;;; * Neither the name of the Institute for Artificial Intelligence/
;;; Universitaet Bremen nor the names of its contributors may be used to
;;; endorse or promote products derived from this software without specific
;;; prior written permission.
;;;
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;; POSSIBILITY OF SUCH DAMAGE.

(in-package :cl-tf2)

;;;
;;; Users can use the 'header' class and its related functionality to wrap data in a 
;;; tf-friendly way, i.e. with a frame-id and stamp. The convenience macro 'def-stamped'
;;; shall ease the programming effort when plugging a new datatype into tf-reasoning.
;;;

(defclass header ()
  ((frame-id :initarg :frame-id :initform ""
             :reader frame-id :type string
             :documentation "ID of the reference frame of data.")
   (stamp :initarg :stamp :initform 0.0
          :reader stamp :type float
          :documentation "Time-stamp at which data was measured."))
  (:documentation "Utility class to wrap some measurement data with a
 time-stamp and reference frame-id."))

(defun make-header (frame-id stamp)
  "Creates an instance of type 'header' with `frame-id' and `stamp'."
  (declare (type string frame-id)
           (type number stamp))
  (make-instance 'header :frame-id frame-id :stamp stamp))

(defmethod print-object ((obj header) strm)
  "Overloads pretty printing of instances of type 'header'"
  (print-unreadable-object (obj strm :type t)
    (with-slots (frame-id stamp) obj
      (format strm "(FRAME-ID: \"~a\" STAMP: ~a)" frame-id stamp))))

(defmacro def-stamped (name (slot-name slot-type &key (initform nil initform-supplied-p)))
  "Convenience macro to define a stamped datatype class to wrap a datatype with a
 header. This macro will also define some convenience functions, and overload methods
 for the new stamped datatype. `name' will be the name of the new class, `slot-name' 
 the name of the slot storing the wrapped data, and `slot-type' is the type of the 
 wrapped data. Additionally, the new class will have a slot 'header' of type 'header.
 Optionally, an `initform' for the wrapped data can be specified.

 Example usage for creating a stamped number: 
   (def-stamped number-stamped (num-value number :initform 0.0))

 This call will:
   - define a class 'number-stamped' with slots 'num-value' and 'header'
   - define a constructor-function 'make-number-stamped'
   - define a function 'copy-number-stamped'
   - define a function 'copy-ext-number-stamped'
   - overload the method 'print-object' for 'number-stamped'
   - overload the method 'get-time-stamp' for 'number-stamped'
   - overload the method 'get-frame-id' for 'number-stamped'"

  (labels ((to-keyword (sym)
             (intern (string sym) 'keyword))
           (combine-symbols (symbols)
             (intern (format nil "~{~a~}" symbols)))
           (constructor-symbol (name)
             (combine-symbols `("MAKE-" ,(symbol-name name))))
           (copy-constructor-symbol (name)
             (combine-symbols `("COPY-" ,(symbol-name name))))
           (copy-constructor-ext-symbol (name)
             (combine-symbols `("COPY-EXT-" ,(symbol-name name)))))
    (unless (sb-mop:class-finalized-p (find-class slot-type))
      (sb-mop:finalize-inheritance (find-class slot-type)))
    (unless (sb-mop:class-finalized-p (find-class 'cl-tf2:header))
      (sb-mop:finalize-inheritance (find-class 'cl-tf2:header)))
    `(progn
       (defclass ,name ()
         ((header :initarg :header :initform (make-instance 'cl-tf2:header)
                  :accessor header :type cl-tf2:header)
          ,(if initform-supplied-p
               `(,slot-name :initarg ,(to-keyword slot-name) :type ,slot-type
                            :accessor ,slot-name :initform ,initform)
               `(,slot-name :initarg ,(to-keyword slot-name) :type ,slot-type
                            :accessor ,slot-name))))
       (defgeneric ,(constructor-symbol name)
           ,`(,slot-name ,@(loop for slot in (sb-mop:class-slots (find-class 'cl-tf2:header))
                                 as slot-symbol = (intern (symbol-name
                                                           (sb-mop:slot-definition-name slot)))
                                 collect slot-symbol))
         (:method
             ,(append
               `(,slot-name)
               `,(loop for slot in (append
                                    (sb-mop:class-slots (find-class 'cl-tf2:header)))
                       as slot-symbol = (intern (symbol-name
                                                 (sb-mop:slot-definition-name slot)))
                       as slot-type = (sb-mop:slot-definition-type slot)
                       collect `(,slot-symbol ,slot-type)))
           (make-instance
            ',name ,(to-keyword slot-name) ,slot-name
            :header (cl-tf2:make-header
                     ,@(loop for slot in (append
                                          (sb-mop:class-slots (find-class 'cl-tf2:header)))
                             as slot-symbol = (intern (symbol-name
                                                       (sb-mop:slot-definition-name slot)))
                             collect slot-symbol)))))
       (defgeneric ,(copy-constructor-symbol name) (,name &key header ,slot-name)
         (:method ((,name ,name) &key (header 'cl-tf2:header) (,slot-name ',slot-type))
           (with-slots ((old-header header) (old-data ,slot-name)) ,name
             (make-instance ',name
                            :header (or header old-header)
                            ,(to-keyword slot-name) (or ,slot-name old-data)))))
       (defgeneric ,(copy-constructor-ext-symbol name)
           ,(append
             `(,name &key)
             `,(loop for slot in (append
                                  (sb-mop:class-slots (find-class slot-type))
                                  (sb-mop:class-slots (find-class 'cl-tf2:header)))
                     as slot-symbol = (intern (symbol-name
                                               (sb-mop:slot-definition-name slot)))
                     collect slot-symbol))
         (:method
           ,(append
             `((,name ,name) &key)
             `,(loop for slot in (append
                                  (sb-mop:class-slots (find-class slot-type))
                                  (sb-mop:class-slots (find-class 'cl-tf2:header)))
                     as slot-symbol = (intern (symbol-name
                                               (sb-mop:slot-definition-name slot)))
                     collect `(,slot-symbol
                               nil
                               ,(combine-symbols `(,slot-symbol "-" p)))))
           ,(concatenate
             'string
             "Copies the object given as `" (write-to-string name) "' "
             "and exposes all of its slots' sub-slots as key parameters. Parameters that are omitted are defaulting to the values in `"
             (write-to-string name) "'.")
           (declare
            ,@(loop for slot in (append (sb-mop:class-slots
                                         (find-class slot-type))
                                        (sb-mop:class-slots
                                         (find-class 'cl-tf2:header)))
                    collect `(type (or null ,(sb-mop:slot-definition-type slot))
                                   ,(intern (symbol-name
                                             (sb-mop:slot-definition-name slot))))))
           (make-instance
            ',name
            ,@(loop for (class-slot class) in `((,slot-name ,slot-type)
                                                (cl-tf2:header cl-tf2:header))
                    append
                    `(,(to-keyword class-slot)
                      (make-instance
                       ',class
                       ,@(loop for slot in (sb-mop:class-slots (find-class class))
                               as sub-slot-name = (sb-mop:slot-definition-name slot)
                               append
                               `(,(to-keyword sub-slot-name)
                                 (or (when ,(combine-symbols
                                             `(,(intern (symbol-name sub-slot-name))
                                               "-" p))
                                       ,(intern (symbol-name sub-slot-name)))
                                     (,sub-slot-name (,class-slot ,name)))))))))))
       (defmethod print-object ((obj ,name) strm)
         (print-unreadable-object (obj strm :type t)
           (with-slots (header ,slot-name) obj
             (format strm "~%  HEADER:~%    ~a~%  ~a:~%    ~a" 
                     header ,(string slot-name) ,slot-name))))
       (defmethod cl-tf2:get-time-stamp ((object ,name))
         (cl-tf2:stamp (cl-tf2:header object)))
       (defmethod cl-tf2:get-frame-id ((object ,name))
         (cl-tf2:frame-id (cl-tf2:header object))))))
