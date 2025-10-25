<?xml version="1.0" encoding="utf-8"?>
<!--  Created with RPTDSSSLPARAMXML.M
      Copyright 1997-2005 The MathWorks, Inc.
      $Revision: 1.1.8.1.12.1 $  $Date: 2006/07/12 17:38:48 $ -->
<stylesheet>
<varpair><varname>%generate-set-toc%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%generate-book-toc%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>($generate-book-lot-list$)</varname><varvalue>(list (normalize "table")
(normalize "figure")
(normalize "example")
(normalize "equation"))</varvalue></varpair>
<varpair><varname>%generate-part-toc%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%generate-part-toc-on-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-reference-toc%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%generate-reference-toc-on-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-article-toc%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%generate-article-toc-on-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-set-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-book-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-part-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-partintro-on-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-reference-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-article-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-article-titlepage-on-separate-page%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%titlepage-in-info-order%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%author-othername-in-middle%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%refentry-new-page%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%refentry-keep%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%refentry-generate-name%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%refentry-xref-italic%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%refentry-xref-manvolnum%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%funcsynopsis-style%</varname><varvalue>'ansi</varvalue></varpair>
<varpair><varname>%kr-funcsynopsis-indent%</varname><varvalue>1pi</varvalue></varpair>
<varpair><varname>%funcsynopsis-decoration%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%refentry-name-font-family%</varname><varvalue>%mono-font-family%</varvalue></varpair>
<varpair><varname>%title-font-family%</varname><varvalue>"Arial"</varvalue></varpair>
<varpair><varname>%body-font-family%</varname><varvalue>"Times New Roman"</varvalue></varpair>
<varpair><varname>%mono-font-family%</varname><varvalue>"Courier New"</varvalue></varpair>
<varpair><varname>%admon-font-family%</varname><varvalue>"Arial"</varvalue></varpair>
<varpair><varname>%guilabel-font-family%</varname><varvalue>"Arial"</varvalue></varpair>
<varpair><varname>%visual-acuity%</varname><varvalue>"normal"</varvalue></varpair>
<varpair><varname>%hsize-bump-factor%</varname><varvalue>1.2</varvalue></varpair>
<varpair><varname>%smaller-size-factor%</varname><varvalue>0.9</varvalue></varpair>
<varpair><varname>%ss-size-factor%</varname><varvalue>0.6</varvalue></varpair>
<varpair><varname>%ss-shift-factor%</varname><varvalue>0.4</varvalue></varpair>
<varpair><varname>%verbatim-size-factor%</varname><varvalue>0.9</varvalue></varpair>
<varpair><varname>%bf-size%</varname><varvalue>(case %visual-acuity%
(("tiny") 8pt)
(("normal") 10pt)
(("presbyopic") 12pt)
(("large-type") 24pt))</varvalue></varpair>
<!-- (define-unit em %bf-size%) -->
<varpair><varname>%footnote-size-factor%</varname><varvalue>0.9</varvalue></varpair>
<varpair><varname>tex-backend</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>mif-backend</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>rtf-backend</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>default-backend</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>(print-backend)</varname><varvalue>(cond
(tex-backend 'tex)
(mif-backend 'mif)
(rtf-backend 'rtf)
(else default-backend))</varvalue></varpair>
<varpair><varname>%verbatim-default-width%</varname><varvalue>80</varvalue></varpair>
<varpair><varname>%number-synopsis-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%number-funcsynopsisinfo-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%number-literallayout-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%number-address-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%number-programlisting-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%number-screen-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%linenumber-mod%</varname><varvalue>5</varvalue></varpair>
<varpair><varname>%linenumber-length%</varname><varvalue>3</varvalue></varpair>
<varpair><varname>%linenumber-padchar%</varname><varvalue>"\no-break-space;"</varvalue></varpair>
<varpair><varname>($linenumber-space$)</varname><varvalue>(literal "\no-break-space;")</varvalue></varpair>
<varpair><varname>%indent-synopsis-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%indent-funcsynopsisinfo-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%indent-literallayout-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%indent-address-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%indent-programlisting-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%indent-screen-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%callout-fancy-bug%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%callout-default-col%</varname><varvalue>60</varvalue></varpair>
<varpair><varname>%section-autolabel%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%chapter-autolabel%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%label-preface-sections%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%qanda-inherit-numeration%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%chap-app-running-heads%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%chap-app-running-head-autolabel%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%paper-type%</varname><varvalue>"USletter"</varvalue></varpair>
<varpair><varname>%two-side%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%writing-mode%</varname><varvalue>'left-to-right</varvalue></varpair>
<varpair><varname>%page-n-columns%</varname><varvalue>1</varvalue></varpair>
<varpair><varname>%titlepage-n-columns%</varname><varvalue>1</varvalue></varpair>
<varpair><varname>%page-column-sep%</varname><varvalue>0.5in</varvalue></varpair>
<varpair><varname>%page-balance-columns?%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%left-margin%</varname><varvalue>6pi</varvalue></varpair>
<varpair><varname>%right-margin%</varname><varvalue>6pi</varvalue></varpair>
<varpair><varname>%page-width%</varname><varvalue>(case %paper-type%
(("A4landscape") 297mm)
(("USletter") 8.5in)
(("USlandscape") 11in)
(("4A0") 1682mm)
(("2A0") 1189mm)
(("A0") 841mm)
(("A1") 594mm)
(("A2") 420mm)
(("A3") 297mm)
(("A4") 210mm)
(("A5") 148mm)
(("A6") 105mm)
(("A7") 74mm)
(("A8") 52mm)
(("A9") 37mm)
(("A10") 26mm)
(("B0") 1000mm)
(("B1") 707mm)
(("B2") 500mm)
(("B3") 353mm)
(("B4") 250mm)
(("B5") 176mm)
(("B6") 125mm)
(("B7") 88mm)
(("B8") 62mm)
(("B9") 44mm)
(("B10") 31mm)
(("C0") 917mm)
(("C1") 648mm)
(("C2") 458mm)
(("C3") 324mm)
(("C4") 229mm)
(("C5") 162mm)
(("C6") 114mm)
(("C7") 81mm)
(("C8") 57mm)
(("C9") 40mm)
(("C10") 28mm))</varvalue></varpair>
<varpair><varname>%page-height%</varname><varvalue>(case %paper-type%
(("A4landscape") 210mm)
(("USletter") 11in)
(("USlandscape") 8.5in)
(("4A0") 2378mm)
(("2A0") 1682mm)
(("A0") 1189mm)
(("A1") 841mm)
(("A2") 594mm)
(("A3") 420mm)
(("A4") 297mm)
(("A5") 210mm)
(("A6") 148mm)
(("A7") 105mm)
(("A8") 74mm)
(("A9") 52mm)
(("A10") 37mm)
(("B0") 1414mm)
(("B1") 1000mm)
(("B2") 707mm)
(("B3") 500mm)
(("B4") 353mm)
(("B5") 250mm)
(("B6") 176mm)
(("B7") 125mm)
(("B8") 88mm)
(("B9") 62mm)
(("B10") 44mm)
(("C0") 1297mm)
(("C1") 917mm)
(("C2") 648mm)
(("C3") 458mm)
(("C4") 324mm)
(("C5") 229mm)
(("C6") 162mm)
(("C7") 114mm)
(("C8") 81mm)
(("C9") 57mm)
(("C10") 40mm))</varvalue></varpair>
<varpair><varname>%text-width%</varname><varvalue>(- %page-width% (+ %left-margin% %right-margin%))</varvalue></varpair>
<varpair><varname>%body-width%</varname><varvalue>(- %text-width% %body-start-indent%)</varvalue></varpair>
<varpair><varname>%top-margin%</varname><varvalue>(if (equal? %visual-acuity% "large-type")
7.5pi
6pi)</varvalue></varpair>
<varpair><varname>%bottom-margin%</varname><varvalue>(if (equal? %visual-acuity% "large-type")
9.5pi
8pi)</varvalue></varpair>
<varpair><varname>%header-margin%</varname><varvalue>(if (equal? %visual-acuity% "large-type")
5.5pi
4pi)</varvalue></varpair>
<varpair><varname>%footer-margin%</varname><varvalue>4pi</varvalue></varpair>
<varpair><varname>%page-number-restart%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%article-page-number-restart%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%generate-heading-level%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%admon-graphics%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%admon-graphics-path%</varname><varvalue>"../images/"</varvalue></varpair>
<varpair><varname>($admon-graphic$ #!optional (nd (current-node)))</varname><varvalue>(cond ((equal? (gi nd) (normalize "tip"))
(string-append %admon-graphics-path% "tip.gif"))
((equal? (gi nd) (normalize "note"))
(string-append %admon-graphics-path% "note.gif"))
((equal? (gi nd) (normalize "important"))
(string-append %admon-graphics-path% "important.gif"))
((equal? (gi nd) (normalize "caution"))
(string-append %admon-graphics-path% "caution.gif"))
((equal? (gi nd) (normalize "warning"))
(string-append %admon-graphics-path% "warning.gif"))
(else (error (string-append (gi nd) " is not an admonition."))))</varvalue></varpair>
<varpair><varname>($admon-graphic-width$ #!optional (nd (current-node)))</varname><varvalue>0.3in</varvalue></varpair>
<varpair><varname>%default-quadding%</varname><varvalue>'start</varvalue></varpair>
<varpair><varname>%division-title-quadding%</varname><varvalue>'center</varvalue></varpair>
<varpair><varname>%division-subtitle-quadding%</varname><varvalue>'center</varvalue></varpair>
<varpair><varname>%component-title-quadding%</varname><varvalue>'start</varvalue></varpair>
<varpair><varname>%component-subtitle-quadding%</varname><varvalue>'start</varvalue></varpair>
<varpair><varname>%article-title-quadding%</varname><varvalue>'center</varvalue></varpair>
<varpair><varname>%article-subtitle-quadding%</varname><varvalue>'center</varvalue></varpair>
<varpair><varname>%section-title-quadding%</varname><varvalue>'start</varvalue></varpair>
<varpair><varname>%section-subtitle-quadding%</varname><varvalue>'start</varvalue></varpair>
<varpair><varname>biblio-citation-check</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>biblio-filter-used</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>biblio-number</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>biblio-xref-title</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%olink-outline-ext%</varname><varvalue>".olink"</varvalue></varpair>
<varpair><varname>%footnote-ulinks%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>bop-footnotes</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%graphic-default-extension%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%graphic-extensions%</varname><varvalue>'("eps" "epsf" "gif" "tif" "tiff" "jpg" "jpeg" "png")</varvalue></varpair>
<varpair><varname>image-library</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>image-library-filename</varname><varvalue>"imagelib/imagelib.xml"</varvalue></varpair>
<varpair><varname>($table-element-list$)</varname><varvalue>(list (normalize "table") (normalize "informaltable"))</varvalue></varpair>
<varpair><varname>%simplelist-column-width%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%default-variablelist-termlength%</varname><varvalue>20</varvalue></varpair>
<varpair><varname>%may-format-variablelist-as-table%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%always-format-variablelist-as-table%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%line-spacing-factor%</varname><varvalue>1.3</varvalue></varpair>
<varpair><varname>%head-before-factor%</varname><varvalue>0.75</varvalue></varpair>
<varpair><varname>%head-after-factor%</varname><varvalue>0.5</varvalue></varpair>
<varpair><varname>%body-start-indent%</varname><varvalue>4pi</varvalue></varpair>
<varpair><varname>%para-sep%</varname><varvalue>(/ %bf-size% 2.0)</varvalue></varpair>
<varpair><varname>%block-sep%</varname><varvalue>(* %para-sep% 2.0)</varvalue></varpair>
<varpair><varname>%para-indent%</varname><varvalue>0pt</varvalue></varpair>
<varpair><varname>%para-indent-firstpara%</varname><varvalue>0pt</varvalue></varpair>
<varpair><varname>%block-start-indent%</varname><varvalue>0pt</varvalue></varpair>
<varpair><varname>%example-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%figure-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%table-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%equation-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%informalexample-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%informalfigure-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%informaltable-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%informalequation-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%object-rule-thickness%</varname><varvalue>2pt</varvalue></varpair>
<varpair><varname>($object-titles-after$)</varname><varvalue>'()</varvalue></varpair>
<varpair><varname>formal-object-float</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%default-title-end-punct%</varname><varvalue>"."</varvalue></varpair>
<varpair><varname>%content-title-end-punct%</varname><varvalue>'(#\. #\! #\?)</varvalue></varpair>
<varpair><varname>%honorific-punctuation%</varname><varvalue>"."</varvalue></varpair>
<varpair><varname>%default-simplesect-level%</varname><varvalue>4</varvalue></varpair>
<varpair><varname>%show-ulinks%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%show-comments%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>firstterm-bold</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%min-leading%</varname><varvalue>2pt</varvalue></varpair>
<varpair><varname>%hyphenation%</varname><varvalue>#f</varvalue></varpair>
<!-- (declare-initial-value writing-mode 	%writing-mode%) -->
<!-- (declare-initial-value input-whitespace-treatment 'collapse) -->
<!-- (declare-initial-value left-margin 	%left-margin%) -->
<!-- (declare-initial-value right-margin 	%right-margin%) -->
<!-- (declare-initial-value page-width	%page-width%) -->
<!-- (declare-initial-value page-height	%page-height%) -->
<!-- (declare-initial-value min-leading %min-leading%) -->
<!-- (declare-initial-value top-margin	%top-margin%) -->
<!-- (declare-initial-value bottom-margin	%bottom-margin%) -->
<!-- (declare-initial-value header-margin	%header-margin%) -->
<!-- (declare-initial-value footer-margin	%footer-margin%) -->
</stylesheet>
