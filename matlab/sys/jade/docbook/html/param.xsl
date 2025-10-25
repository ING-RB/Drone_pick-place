<?xml version="1.0" encoding="utf-8"?>
<!--  Created with RPTDSSSLPARAMXML.M
      Copyright 1997-2005 The MathWorks, Inc.
      $Revision: 1.1.8.1.12.1 $  $Date: 2006/07/12 17:37:02 $ -->
<stylesheet>
<varpair><varname>%generate-set-toc%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-book-toc%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>($generate-book-lot-list$)</varname><varvalue>(list (normalize "table")
(normalize "figure")
(normalize "example")
(normalize "equation"))</varvalue></varpair>
<varpair><varname>%generate-part-toc%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-part-toc-on-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>$generate-chapter-toc$</varname><varvalue>(lambda ()
(or (not nochunks)
(node-list=? (current-node) (sgml-root-element))))</varvalue></varpair>
<varpair><varname>%force-chapter-toc%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%generate-article-toc%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%generate-reference-toc%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-reference-toc-on-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%annotate-toc%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>($generate-qandaset-toc$)</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-set-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-book-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-part-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-partintro-on-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-reference-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%generate-article-titlepage%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%titlepage-in-info-order%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%generate-legalnotice-link%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>($legalnotice-link-file$ legalnotice)</varname><varvalue>(string-append "ln"
(number->string (all-element-number legalnotice))
%html-ext%)</varvalue></varpair>
<varpair><varname>%author-othername-in-middle%</varname><varvalue>#t</varvalue></varpair>
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
<varpair><varname>($admon-graphic-width$ #!optional (nd (current-node)))</varname><varvalue>"25"</varvalue></varpair>
<varpair><varname>%callout-graphics%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%callout-graphics-path%</varname><varvalue>"../images/callouts/"</varvalue></varpair>
<varpair><varname>%callout-graphics-number-limit%</varname><varvalue>10</varvalue></varpair>
<varpair><varname>%always-format-variablelist-as-table%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%default-variablelist-termlength%</varname><varvalue>20</varvalue></varpair>
<varpair><varname>%may-format-variablelist-as-table%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%header-navigation%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%footer-navigation%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%gentext-nav-tblwidth%</varname><varvalue>"100%"</varvalue></varpair>
<varpair><varname>%gentext-nav-use-ff%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%gentext-nav-use-tables%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%indent-address-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%indent-funcsynopsisinfo-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%indent-literallayout-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%indent-programlisting-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%indent-screen-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%indent-synopsis-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%number-address-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%number-funcsynopsisinfo-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%number-literallayout-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%number-programlisting-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%number-screen-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%number-synopsis-lines%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%linenumber-length%</varname><varvalue>3</varvalue></varpair>
<varpair><varname>%linenumber-mod%</varname><varvalue>5</varvalue></varpair>
<varpair><varname>%linenumber-padchar%</varname><varvalue>" "</varvalue></varpair>
<varpair><varname>($linenumber-space$)</varname><varvalue>(make entity-ref name: "nbsp")</varvalue></varpair>
<varpair><varname>%shade-verbatim%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>($shade-verbatim-attr$)</varname><varvalue>(list
(list "BORDER" "0")
(list "BGCOLOR" "#E0E0E0")
(list "WIDTH" ($table-width$)))</varvalue></varpair>
<varpair><varname>%callout-default-col%</varname><varvalue>60</varvalue></varpair>
<varpair><varname>%chapter-autolabel%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%section-autolabel%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%label-preface-sections%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%qanda-inherit-numeration%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%cals-table-class%</varname><varvalue>"CALSTABLE"</varvalue></varpair>
<varpair><varname>($table-element-list$)</varname><varvalue>(list (normalize "table") (normalize "informaltable"))</varvalue></varpair>
<varpair><varname>($table-width$)</varname><varvalue>(if (has-ancestor-member? (current-node) '("LISTITEM"))
"90%"
"100%")</varvalue></varpair>
<varpair><varname>%simplelist-column-width%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>biblio-citation-check</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>biblio-filter-used</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>biblio-number</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>biblio-xref-title</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%olink-fragid%</varname><varvalue>"&#38;fragid="</varvalue></varpair>
<varpair><varname>%olink-outline-ext%</varname><varvalue>".olink"</varvalue></varpair>
<varpair><varname>%olink-pubid%</varname><varvalue>"pubid="</varvalue></varpair>
<varpair><varname>%olink-resolution%</varname><varvalue>"/cgi-bin/olink?"</varvalue></varpair>
<varpair><varname>%olink-sysid%</varname><varvalue>"sysid="</varvalue></varpair>
<varpair><varname>%graphic-default-extension%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%graphic-extensions%</varname><varvalue>'("gif" "jpg" "jpeg" "png" "tif" "tiff" "eps" "epsf")</varvalue></varpair>
<varpair><varname>image-library</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>image-library-filename</varname><varvalue>"imagelib/imagelib.xml"</varvalue></varpair>
<varpair><varname>%body-attr%</varname><varvalue>(list
(list "BGCOLOR" "#FFFFFF")
(list "TEXT" "#000000")
(list "LINK" "#0000FF")
(list "VLINK" "#840084")
(list "ALINK" "#0000FF"))</varvalue></varpair>
<varpair><varname>%html-prefix%</varname><varvalue>""</varvalue></varpair>
<varpair><varname>%html-use-lang-in-filename%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%html-ext%</varname><varvalue>".htm"</varvalue></varpair>
<varpair><varname>%html-header-tags%</varname><varvalue>'()</varvalue></varpair>
<varpair><varname>%html-pubid%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%root-filename%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>html-index</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>html-index-filename</varname><varvalue>"HTML.index"</varvalue></varpair>
<varpair><varname>html-manifest</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>html-manifest-filename</varname><varvalue>"HTML.manifest"</varvalue></varpair>
<varpair><varname>nochunks</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>rootchunk</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>use-output-dir</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%output-dir%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%stylesheet%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%stylesheet-type%</varname><varvalue>"text/css"</varvalue></varpair>
<varpair><varname>%use-id-as-filename%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%refentry-generate-name%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%refentry-xref-italic%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%refentry-xref-manvolnum%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%funcsynopsis-decoration%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%funcsynopsis-style%</varname><varvalue>'ansi</varvalue></varpair>
<varpair><varname>%html40%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%css-decoration%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%css-liststyle-alist%</varname><varvalue>'(("bullet" "disc")
("box" "square"))</varvalue></varpair>
<varpair><varname>%fix-para-wrappers%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%spacing-paras%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%example-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%figure-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%table-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%equation-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%informalexample-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%informalfigure-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%informaltable-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%informalequation-rules%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%content-title-end-punct%</varname><varvalue>'(#\. #\! #\?)</varvalue></varpair>
<varpair><varname>%honorific-punctuation%</varname><varvalue>"."</varvalue></varpair>
<varpair><varname>%default-quadding%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%default-simplesect-level%</varname><varvalue>4</varvalue></varpair>
<varpair><varname>%default-title-end-punct%</varname><varvalue>"."</varvalue></varpair>
<varpair><varname>%footnotes-at-end%</varname><varvalue>#t</varvalue></varpair>
<varpair><varname>%link-mailto-url%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%show-comments%</varname><varvalue>#f</varvalue></varpair>
<varpair><varname>%writing-mode%</varname><varvalue>'left-to-right</varvalue></varpair>
<varpair><varname>($object-titles-after$)</varname><varvalue>'()</varvalue></varpair>
<varpair><varname>firstterm-bold</varname><varvalue>#f</varvalue></varpair>
<!-- (declare-initial-value writing-mode %writing-mode%) -->
</stylesheet>
