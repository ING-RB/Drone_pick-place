<?xml version="1.0" encoding="utf-8"?>

<!--
This is an XSL stylesheet which converts mscript XML files into FO
Use the XSLT command to perform the conversion.

This is intended to be included inside another XSL file, not used standalone.

When EntityResolvers work properly, this should be moved to its own directory.

Copyright 1997-2023 The MathWorks, Inc.
-->

<xsl:stylesheet
  version="1.0"
  xmlns:xsl  = "http://www.w3.org/1999/XSL/Transform"
  xmlns:fo   = "http://www.w3.org/1999/XSL/Format"
  xmlns:mwsh = "http://www.mathworks.com/namespace/mcode/v1/syntaxhighlight.dtd">
  <xsl:param name="code.keyword">#0e00ff</xsl:param>
  <xsl:param name="code.comment">#028009</xsl:param>
  <xsl:param name="code.string">#aa04f9</xsl:param>
  <xsl:param name="code.untermstring">#c40000</xsl:param>
  <xsl:param name="code.syscmd">#b28c00</xsl:param>
  <xsl:param name="code.typesection">#a0522c</xsl:param>    
  <xsl:strip-space elements="mwsh:code"/>

<!--wrap-option='no-wrap'-->
<xsl:template match="mwsh:code"><fo:block
                white-space-collapse="false"
                linefeed-treatment="preserve"
                xsl:use-attribute-sets="monospace.verbatim.properties"><xsl:apply-templates/></fo:block></xsl:template>

<xsl:template match="mwsh:keywords">
  <fo:inline color="{$code.keyword}"><xsl:value-of select="."/></fo:inline>
</xsl:template>

<xsl:template match="mwsh:strings">
  <fo:inline color="{$code.string}"><xsl:value-of select="."/></fo:inline>
</xsl:template>

<xsl:template match="mwsh:comments">
  <fo:inline color="{$code.comment}"><xsl:value-of select="."/></fo:inline>
</xsl:template>

<xsl:template match="mwsh:unterminated_strings">
  <fo:inline color="{$code.untermstring}"><xsl:value-of select="."/></fo:inline>
</xsl:template>

<xsl:template match="mwsh:system_commands">
  <fo:inline color="{$code.syscmd}"><xsl:value-of select="."/></fo:inline>
</xsl:template>

<xsl:template match="mwsh:type_section">
  <fo:inline color="{$code.typesection}"><xsl:value-of select="."/></fo:inline>
</xsl:template>

</xsl:stylesheet>

