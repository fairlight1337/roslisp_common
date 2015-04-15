;;; Copyright (c) 2015 Georg Bartels <georg.bartels@cs.uni-bremen.de>
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

(in-package :cl-transforms-plugin)

;;;
;;; FROM ROS MESSAGE...
;;;

(defun msg->transform-stamped (msg)
  (declare (type geometry_msgs-msg:transformstamped msg))
  (with-fields (header child_frame_id transform) msg
    (make-instance 'transform-stamped 
                   :header (msg->header header)
                   :child-frame-id child_frame_id
                   :transform (msg->transform transform))))

(defun msg->pose-stamped (msg)
  (declare (type geometry_msgs-msg:posestamped msg))
  (with-fields (header pose) msg
    (make-instance 'pose-stamped
                   :header (msg->header header)
                   :pose (msg->pose pose))))

(defun msg->header (msg)
  (declare (type std_msgs-msg:Header msg))
  (with-fields (stamp frame_id) msg
    (make-header frame_id stamp)))

(defun msg->transform (msg)
  (declare (type geometry_msgs-msg:transform msg))
  (with-fields (translation rotation) msg
    (cl-transforms:make-transform
     (msg->3d-vector translation) (msg->quaternion rotation))))

(defun msg->pose (msg)
  (declare (type geometry_msgs-msg:pose msg))
  (with-fields (position orientation) msg
    (cl-transforms:make-pose
     (msg->point position) (msg->quaternion orientation))))

(defun msg->point (msg)
  (declare (type geometry_msgs-msg:point msg))
  (with-fields (x y z) msg
    (cl-transforms:make-3d-vector x y z)))

(defun msg->3d-vector (msg)
  (declare (type geometry_msgs-msg:vector3 msg))
  (with-fields (x y z) msg
    (cl-transforms:make-3d-vector x y z)))

(defun msg->quaternion (msg)
  (declare (type geometry_msgs-msg:quaternion msg))
  (with-fields (x y z w) msg
    (cl-transforms:make-quaternion x y z w)))

;;;
;;; TO ROS MESSAGE...
;;;

(defun transform-stamped->msg (transform-stamped)
  (declare (type transform-stamped transform-stamped))
  (make-msg 
   "geometry_msgs/TransformStamped"
   :header (header->msg (header transform-stamped))
   :child_frame_id (child-frame-id transform-stamped)
   :transform (transform->msg (transform transform-stamped))))

(defun pose-stamped->msg (pose-stamped)
  (declare (type pose-stamped pose-stamped))
  (make-msg 
   "geometry_msgs/PoseStamped"
   :header (header->msg (header pose-stamped))
   :pose (pose->msg (pose pose-stamped))))

(defun header->msg (header)
  (declare (type header header))
  (make-msg "std_msgs/Header" :stamp (stamp header) :frame_id (frame-id header)))

(defun transform->msg (transform)
  (declare (type cl-transforms:transform transform))
  (make-msg 
   "geometry_msgs/Transform"
   :translation (3d-vector->msg (cl-transforms:translation transform))
   :rotation (quaternion->msg (cl-transforms:rotation transform))))

(defun pose->msg (pose)
  (declare (type cl-transforms:pose pose))
  (make-msg
   "geometry_msgs/Pose"
   :position (point->msg (cl-transforms:origin pose))
   :orientation (quaternion->msg (cl-transforms:orientation pose))))

(defun quaternion->msg (quaternion)
  (declare (type cl-transforms:quaternion quaternion))
  (make-msg "geometry_msgs/Quaternion"
            :x (cl-transforms:x quaternion)
            :y (cl-transforms:y quaternion)
            :z (cl-transforms:z quaternion)
            :w (cl-transforms:w quaternion)))

(defun 3d-vector->msg (3d-vector)
  (declare (type cl-transforms:3d-vector 3d-vector))
  (make-msg "geometry_msgs/Vector3"
            :x (cl-transforms:x 3d-vector)
            :y (cl-transforms:y 3d-vector)
            :z (cl-transforms:z 3d-vector)))

(defun point->msg (point)
  (declare (type cl-transforms:point point))
  (make-msg "geometry_msgs/Point"
            :x (cl-transforms:x point)
            :y (cl-transforms:y point)
            :z (cl-transforms:z point)))

(defun pose-stamped->point-stamped-msg (pose-stamped)
  (declare (type pose-stamped pose-stamped))
  (make-message
   "geometry_msgs/PointStamped"
   (stamp header) (cl-tf2:get-time-stamp pose-stamped)
   (frame_id header) (cl-tf2:get-frame-id pose-stamped)
   (x point) (cl-transforms:x
              (cl-transforms:origin
               (cl-transforms-plugin:pose pose-stamped)))
   (y point) (cl-transforms:y
              (cl-transforms:origin
               (cl-transforms-plugin:pose pose-stamped)))
   (z point) (cl-transforms:z
              (cl-transforms:origin
               (cl-transforms-plugin:pose pose-stamped)))))
