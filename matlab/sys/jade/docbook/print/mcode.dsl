;; This is a stylesheet which converts mscript XML files into DSSSL flow flow objects
;;
;; Copyright 1984-2004 The MathWorks, Inc.
;; $Revision: 1.1.8.1.12.2 $  $Date: 2007/04/09 05:34:54 $


(define ($mcode-verbatim-display$ indent line-numbers?)
  (let* ((width-in-chars (if (attribute-string (normalize "width"))
			     (string->number (attribute-string (normalize "width")))
			     %verbatim-default-width%))
	 (fsize (lambda () (if (or (attribute-string (normalize "width"))
				   (not %verbatim-size-factor%))
			       (/ (/ (- %text-width% (inherited-start-indent))
				     width-in-chars)
				  0.7)
			       (* (inherited-font-size)
				  %verbatim-size-factor%))))
	 (vspace (if (INBLOCK?)
		     0pt
		     (if (INLIST?)
			 %para-sep%
			 %block-sep%))))
    (make paragraph
      use: verbatim-style
      space-before: (if (and (string=? (gi (parent)) (normalize "entry"))
 			     (absolute-first-sibling?))
			0pt
			vspace)
      space-after:  (if (and (string=? (gi (parent)) (normalize "entry"))
 			     (absolute-last-sibling?))
			0pt
			vspace)
      font-size: (fsize)
      line-spacing: (* (fsize) %line-spacing-factor%)
      start-indent: (if (INBLOCK?)
			(inherited-start-indent)
			(+ %block-start-indent% (inherited-start-indent)))
      (if (or indent line-numbers?)
	  ($linespecific-line-by-line$ indent line-numbers?)
	  (process-children)))))

(element mwsh:code ($mcode-verbatim-display$
			 #f ;; %indent-programlisting-lines%
			 #f)) ;;%number-programlisting-lines%

(element mwsh:keywords ($color-seq$ "#0000ff"))

(element mwsh:strings  ($color-seq$ "#a020f0"))

(element mwsh:comments ($color-seq$ "#228b22"))

(element mwsh:unterminated_strings  ($color-seq$ "#b20000"))

(element mwsh:system_commands  ($color-seq$ "#b28c00"))

