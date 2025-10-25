<?xml version="1.0" encoding="utf-8"?><!--
   This file created by the MathWorks for the Stylesheet Editor tool.
   It is condensed from:
       param-common.mod.xsl
       param-direct.mod.xsl
       param-switch.mod.xsl

   Edits have been made to remove deprecations and messages.

   Created using rptlatexparam.m

   $Revision: 1.1.8.1 $  $Date: 2005/06/09 21:42:28 $
--><xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	
	<xsl:param name="admon.graphics.path"><xsl:text>figures</xsl:text></xsl:param>
	<xsl:param name="tex.math.in.alt"><xsl:text>latex</xsl:text></xsl:param>
	<xsl:param name="show.comments">
		<xsl:value-of select="$latex.is.draft"/>
	</xsl:param>

	
	<xsl:param name="author.othername.in.middle" select="1"/>

	
	<xsl:param name="biblioentry.item.separator">, </xsl:param>

	
	<xsl:param name="toc.section.depth">4</xsl:param>

	
	<xsl:param name="section.depth">4</xsl:param>

	
	<xsl:param name="graphic.default.extension"/>

	
	<xsl:param name="use.role.for.mediaobject">1</xsl:param>

	
	<xsl:param name="preferred.mediaobject.role"/>

	
	<xsl:param name="formal.title.placement">
		figure not_before
		example before
		equation not_before
		table before
		procedure before
	</xsl:param>

	
	<xsl:param name="insert.xref.page.number">0</xsl:param>

	
	<xsl:param name="ulink.show">1</xsl:param>

	
	<xsl:param name="ulink.footnotes">0</xsl:param>

	
    <xsl:param name="use.role.as.xrefstyle">0</xsl:param>

	<xsl:variable name="default-classsynopsis-language">java</xsl:variable>
	
	<xsl:param name="refentry.xref.manvolnum" select="1"/>
	<xsl:variable name="funcsynopsis.style">kr</xsl:variable>
	<xsl:variable name="funcsynopsis.decoration" select="1"/>
	<xsl:variable name="function.parens">0</xsl:variable>
	
	<xsl:param name="refentry.generate.name" select="1"/>
	<xsl:param name="glossentry.show.acronym" select="'no'"/>

	<xsl:variable name="section.autolabel" select="1"/>
	<xsl:variable name="section.label.includes.component.label" select="0"/>
	<xsl:variable name="chapter.autolabel" select="1"/>
	<xsl:variable name="preface.autolabel" select="0"/>
	<xsl:variable name="part.autolabel" select="1"/>
	<xsl:variable name="qandadiv.autolabel" select="1"/>
	<xsl:variable name="autotoc.label.separator" select="'. '"/>
	<xsl:variable name="qanda.inherit.numeration" select="1"/>
	<xsl:variable name="qanda.defaultlabel">number</xsl:variable>

	<xsl:param name="punct.honorific" select="'.'"/>
	<xsl:param name="stylesheet.result.type" select="'xhtml'"/>
	<xsl:param name="use.svg" select="0"/>
	<xsl:param name="formal.procedures" select="1"/>
	<xsl:param name="xref.with.number.and.title" select="1"/>
	<xsl:param name="xref.label-title.separator">: </xsl:param>
	<xsl:param name="xref.label-page.separator"><xsl:text> </xsl:text></xsl:param>
	<xsl:param name="xref.title-page.separator"><xsl:text> </xsl:text></xsl:param>

    <xsl:variable name="check.idref">1</xsl:variable>

	
	<xsl:param name="rootid" select="''"/>

    <!--
    <xsl:variable name="link.mailto.url"></xsl:variable>
    <xsl:variable name="toc.list.type">dl</xsl:variable>
    -->



	

	
	<xsl:param name="latex.documentclass"/>

	
	<xsl:param name="latex.maketitle">
		<xsl:text>{\maketitle</xsl:text>
		<xsl:call-template name="generate.latex.pagestyle"/>
		<xsl:text>\thispagestyle{empty}}
</xsl:text>
	</xsl:param>

	
	<xsl:param name="latex.article.preamble.pre">
	</xsl:param>

	
	<xsl:param name="latex.article.preamble.post">
	</xsl:param>

	
	<xsl:param name="latex.article.varsets">
		<xsl:text>
\usepackage{anysize}
\marginsize{2cm}{2cm}{2cm}{2cm}
\renewcommand\floatpagefraction{.9}
\renewcommand\topfraction{.9}
\renewcommand\bottomfraction{.9}
\renewcommand\textfraction{.1}

		</xsl:text>
	</xsl:param>

	
	<xsl:param name="latex.book.preamble.pre">
	</xsl:param>

	
	<xsl:param name="latex.book.preamble.post">
	</xsl:param>

	
	<xsl:param name="latex.book.varsets">
		<xsl:text>\usepackage{anysize}
</xsl:text>
		<xsl:text>\marginsize{3cm}{2cm}{1.25cm}{1.25cm}
</xsl:text>
	</xsl:param>

	
	<xsl:param name="latex.book.begindocument">
		<xsl:text>\begin{document}
</xsl:text>
	</xsl:param>

	
	<xsl:param name="latex.book.afterauthor">
		<xsl:text>% --------------------------------------------
</xsl:text>
		<xsl:text>\makeglossary
</xsl:text>
		<xsl:text>% --------------------------------------------
</xsl:text>
	</xsl:param>

	
	<xsl:template name="latex.thead.row.entry">
		<xsl:apply-templates/>
	</xsl:template>

	
	<xsl:template name="latex.tfoot.row.entry">
		<xsl:apply-templates/>
	</xsl:template>

	
	<xsl:param name="latex.inline.monoseq.style">\frenchspacing\texttt</xsl:param>

	
	<xsl:param name="latex.article.title.style">\textbf</xsl:param>

	
	<xsl:param name="latex.book.article.title.style">\Large\textbf</xsl:param>

	
	<xsl:param name="latex.book.article.header.style">\textsf</xsl:param>

	
	<xsl:param name="latex.equation.caption.style"/>

	
	<xsl:param name="latex.example.caption.style"/>

	
	<xsl:param name="latex.figure.caption.style"/>

	
	<xsl:param name="latex.figure.title.style"/>

	
	<xsl:param name="latex.formalpara.title.style">\textbf</xsl:param>

	
	<xsl:param name="latex.list.title.style">\sc</xsl:param>

	
	<xsl:param name="latex.admonition.title.style">\bfseries \sc\large</xsl:param>

	
	<xsl:param name="latex.procedure.title.style">\sc</xsl:param>

	
	<xsl:param name="latex.segtitle.style">\em</xsl:param>

	
	<xsl:param name="latex.step.title.style">\bf</xsl:param>

	
	<xsl:param name="latex.table.caption.style"/>

	<xsl:param name="latex.fancyhdr.lh">Left Header</xsl:param>
	<xsl:param name="latex.fancyhdr.ch">Center Header</xsl:param>
	<xsl:param name="latex.fancyhdr.rh">Right Header</xsl:param>
	<xsl:param name="latex.fancyhdr.lf">Left Footer</xsl:param>
	<xsl:param name="latex.fancyhdr.cf">Center Footer</xsl:param>
	<xsl:param name="latex.fancyhdr.rf">Right Footer</xsl:param>

	
	<xsl:param name="latex.pagestyle"/>

	
	<xsl:param name="latex.hyperref.param.common">bookmarksnumbered,colorlinks,backref,bookmarks,breaklinks,linktocpage,plainpages=false</xsl:param>

	
	<xsl:param name="latex.hyperref.param.pdftex">pdfstartview=FitH</xsl:param>
	
	<xsl:param name="latex.hyperref.param.dvips"/>

	
	<xsl:param name="latex.varioref.options">
		<xsl:if test="$latex.language.option!='none'">
			<xsl:value-of select="$latex.language.option"/>
		</xsl:if>
	</xsl:param>

	
	<xsl:template name="latex.vpageref.options">on this page</xsl:template>

	
	<xsl:param name="latex.fancyvrb.tabsize">3</xsl:param>

	
	<xsl:template name="latex.fancyvrb.options"/>

	
	<xsl:param name="latex.inputenc">latin1</xsl:param>

	
	<xsl:param name="latex.fontenc"/>

	
	<xsl:param name="latex.ucs.options"/>

	
	<xsl:param name="latex.babel.language"/>

	
	<xsl:param name="latex.bibwidelabel">
		<xsl:choose>
			<xsl:when test="$latex.biblioentry.style='ieee' or $latex.biblioentry.style='IEEE'">
				<xsl:text>123</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>WIDELABEL</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:param>

	
	<xsl:param name="latex.documentclass.common"/>

	
	<xsl:param name="latex.documentclass.article">a4paper,10pt,twoside,twocolumn</xsl:param>

	
	<xsl:param name="latex.documentclass.book">a4paper,10pt,twoside,openright</xsl:param>

	
	<xsl:param name="latex.documentclass.pdftex"/>

	
	<xsl:param name="latex.documentclass.dvips"/>

	
	<xsl:param name="latex.admonition.imagesize">width=1cm</xsl:param>

	
	<xsl:param name="latex.titlepage.file">title</xsl:param>
    
    <xsl:param name="latex.document.font">palatino</xsl:param>

	
	<xsl:param name="latex.override"/>



	

	
	<xsl:param name="latex.caption.lot.titles.only">1</xsl:param>

	
	<xsl:param name="latex.bibfiles"/>

    
	<xsl:param name="latex.math.support">1</xsl:param>

    
	<xsl:param name="latex.output.revhistory">1</xsl:param>

    
    <xsl:template name="latex.fancybox.options">
	</xsl:template>

    
	<xsl:param name="latex.pdf.support">1</xsl:param>

	
	<xsl:param name="latex.generate.indexterm">1</xsl:param>

	
	<xsl:param name="latex.hyphenation.tttricks">0</xsl:param>

	
	<xsl:param name="latex.decimal.point"/>

	
	<xsl:param name="latex.trim.verbatim">0</xsl:param>

	
	<xsl:param name="latex.use.ltxtable">0</xsl:param>

	
	<xsl:param name="latex.use.longtable">0</xsl:param>

	
	<xsl:param name="latex.use.overpic">1</xsl:param>

	
	<xsl:param name="latex.use.umoline">0</xsl:param>

	
	<xsl:param name="latex.use.url">1</xsl:param>

	
	<xsl:param name="latex.is.draft"/>

	
	<xsl:param name="latex.use.varioref">
		<xsl:if test="$insert.xref.page.number='1'">1</xsl:if>
	</xsl:param>

	
	<xsl:param name="latex.use.fancyhdr">1</xsl:param>

	
	<xsl:param name="latex.bridgehead.in.lot">1</xsl:param>

	
	<xsl:param name="latex.fancyhdr.truncation.style">io</xsl:param>

	
	<xsl:param name="latex.fancyhdr.truncation.partition">50</xsl:param>

	
	<xsl:param name="latex.fancyhdr.style"/>

	
	<xsl:param name="latex.use.parskip">0</xsl:param>

	
	<xsl:param name="latex.use.noindent">
		<xsl:choose>
			<xsl:when test="$latex.use.parskip=1">
				<xsl:value-of select="0"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="1"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:param>

	
	<xsl:param name="latex.use.subfigure">1</xsl:param>

	
	<xsl:param name="latex.use.rotating">1</xsl:param>

	
	<xsl:param name="latex.use.tabularx">1</xsl:param>

	
	<xsl:param name="latex.use.dcolumn">0</xsl:param>

	
	<xsl:param name="latex.use.hyperref">1</xsl:param>

	
	<xsl:param name="latex.use.fancybox">1</xsl:param>

	
	<xsl:param name="latex.use.fancyvrb">1</xsl:param>

	
	<xsl:param name="latex.use.isolatin1">0</xsl:param>

	
	<xsl:param name="latex.use.ucs">0</xsl:param>

	
	<xsl:param name="latex.biblio.output">all</xsl:param>

	
	<xsl:param name="latex.biblioentry.style"/>

	
	<xsl:param name="latex.caption.swapskip">1</xsl:param>

	
	<xsl:param name="latex.graphics.formats"/>

	
	<xsl:param name="latex.entities"/>

	
	<xsl:param name="latex.otherterm.is.preferred">1</xsl:param>

	
	<xsl:param name="latex.alt.is.preferred">1</xsl:param>

	
	<xsl:param name="latex.apply.title.templates">1</xsl:param>

	
	<xsl:param name="latex.apply.title.templates.admonitions">1</xsl:param>

	
	<xsl:param name="latex.url.quotation">1</xsl:param>

	
	<xsl:param name="latex.ulink.protocols.relaxed">1</xsl:param>

	
	<xsl:param name="latex.suppress.blank.page.headers">1</xsl:param>

</xsl:stylesheet>