;; file location: matlabroot/sys/jade/docbook/contrib/header/header.dsl
;;
;; You will need to add this line to your startup.m file:
;;
;; addpath(fullfile(matlabroot,'sys','jade','docbook','contrib','header'))
;;
;; This will allow MATLAB to recognize rptstylesheets.xml
;;
;;  Copyright 1999-2006 The MathWorks, Inc.
;;  $Revision: 1.1 $  $Date: 2000/06/12 18:21:32 $
;;

(define (page-outer-header gi)
  (cond
   ((equal? (normalize gi) (normalize "dedication")) (empty-sosofo))
   ((equal? (normalize gi) (normalize "lot")) (empty-sosofo))
   ((equal? (normalize gi) (normalize "part")) (empty-sosofo))
   ((equal? (normalize gi) (normalize "toc")) (empty-sosofo))
   (else (literal "Type your custom header text here!"))))
