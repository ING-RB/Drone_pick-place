<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

<!-- ********************************************************************
     $Id: htmltbl.xsl 8477 2009-07-13 11:38:55Z nwalsh $
     ********************************************************************

     This file is part of the XSL DocBook Stylesheet distribution.
     See ../README or http://docbook.sf.net/release/xsl/current/ for
     copyright and other information.

     ******************************************************************** -->

<!-- ==================================================================== -->

<xsl:template match="colgroup" mode="htmlTable">
  <xsl:element name="{local-name()}" namespace="">
    <xsl:apply-templates select="@*" mode="htmlTableAtt"/>
    <xsl:apply-templates mode="htmlTable"/>
  </xsl:element>
</xsl:template>

<xsl:template match="col" mode="htmlTable">
  <xsl:element name="{local-name()}" namespace="">
    <xsl:apply-templates select="@*" mode="htmlTableAtt"/>
  </xsl:element>
</xsl:template>

<!-- CHANGE: Replaced the old caption/htmlTable rendering with a blank 
             placeholder and added the caption/htmlTableTitle to appropriately 
             draw the caption as a formatted title 
        
      NOTE* the original caption/htmlTable template follows as caption/oldHtmlTable 
GRA 1-Oct-2008 -->

<xsl:template match="caption" mode="htmlTableTitle">
    <p class="title">
        <b>
            <xsl:apply-templates select="@*" mode="htmlTableAtt"/>
            <xsl:apply-templates select=".." mode="object.title.markup">
                <xsl:with-param name="allow-anchors" select="1"/>
            </xsl:apply-templates>
        </b>
    </p>
</xsl:template>

<xsl:template match="caption" mode="htmlTable"/>

<xsl:template match="caption" mode="oldhtmlTable">
  <!-- do not use xsl:copy because of XHTML's needs -->
  <caption>  
    <xsl:apply-templates select="@*" mode="htmlTableAtt"/>

    <xsl:apply-templates select=".." mode="object.title.markup">
      <xsl:with-param name="allow-anchors" select="1"/>
    </xsl:apply-templates>

  </caption>
</xsl:template>
<!-- @ENDCHANGE -->    

<xsl:template match="tbody|thead|tfoot|tr" mode="htmlTable">
  <xsl:element name="{local-name(.)}">
    <xsl:apply-templates select="@*" mode="htmlTableAtt"/>
    <xsl:apply-templates mode="htmlTable"/>
  </xsl:element>
</xsl:template>

<xsl:template match="th|td" mode="htmlTable">
  <xsl:element name="{local-name(.)}">

<!-- @CHANGE: Added an &nbsp; wherever there was no cell content - 
              (N.b., since '&' is special to xsl, we must use &#160; to 
              replace &nbsp;)
GRA 3-Oct-2008 -->
    <xsl:choose>
      <xsl:when test=". != '' or count(*) != 0">
        <xsl:apply-templates select="@*" mode="htmlTableAtt"/>
        <xsl:apply-templates/> <!-- *not* mode=htmlTable -->
        </xsl:when>
        <xsl:otherwise>
            <xsl:text disable-output-escaping="yes">&#160;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
<!-- @ENDCHANGE -->

  </xsl:element>
</xsl:template>

<!-- @CHANGE: Added this table template to emulate CALS title entries
GRA 30-Sept-2008 -->
<xsl:template match="table[@fastRender='1']|informaltable[@fastRender='1']">
  <xsl:call-template name="anchor">
    <xsl:with-param name="conditional" select="0"/>
  </xsl:call-template>

  <div class="table">
      <xsl:apply-templates select="caption" mode="htmlTableTitle"/>
      <div class="table-contents">
          <table>
              <xsl:attribute name="summary"><xsl:value-of select="caption"/></xsl:attribute>
              <xsl:copy-of select="@*"/>
              <xsl:apply-templates mode="htmlTable"/> 
          </table>
      </div>
  </div>
</xsl:template>
<!-- @ENDCHANGE -->

<!-- don't copy through DocBook-specific attributes on HTML table markup -->
<!-- default behavior is to not copy through because there are more
     DocBook attributes than HTML attributes -->
<xsl:template mode="htmlTableAtt" match="@*"/>

<!-- copy these through -->
<xsl:template mode="htmlTableAtt"
              match="@abbr
                   | @align
                   | @axis
                   | @bgcolor
                   | @border
                   | @cellpadding
                   | @cellspacing
                   | @char
                   | @charoff
                   | @class
                   | @dir
                   | @frame
                   | @headers
                   | @height
                   | @lang
                   | @nowrap
                   | @onclick
                   | @ondblclick
                   | @onkeydown
                   | @onkeypress
                   | @onkeyup
                   | @onmousedown
                   | @onmousemove
                   | @onmouseout
                   | @onmouseover
                   | @onmouseup
                   | @rules
                   | @style
                   | @summary
                   | @title
                   | @valign
                   | @valign
                   | @width
                   | @xml:lang">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="@span|@rowspan|@colspan" mode="htmlTableAtt">
  <!-- No need to copy through the DTD's default value "1" of the attribute -->
  <xsl:if test="number(.) != 1">
    <xsl:attribute name="{local-name(.)}">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:if>
</xsl:template>

<!-- map floatstyle to HTML float values -->
<xsl:template match="@floatstyle" mode="htmlTableAtt">
  <xsl:attribute name="style">
    <xsl:text>float: </xsl:text>
    <xsl:choose>
      <xsl:when test="contains(., 'left')">left</xsl:when>
      <xsl:when test="contains(., 'right')">right</xsl:when>
      <xsl:when test="contains(., 'start')">
        <xsl:value-of select="$direction.align.start"/>
      </xsl:when>
      <xsl:when test="contains(., 'end')">
        <xsl:value-of select="$direction.align.end"/>
      </xsl:when>
      <xsl:when test="contains(., 'inside')">
        <xsl:value-of select="$direction.align.start"/>
      </xsl:when>
      <xsl:when test="contains(., 'outside')">
        <xsl:value-of select="$direction.align.end"/>
      </xsl:when>
      <xsl:when test="contains(., 'before')">none</xsl:when>
      <xsl:when test="contains(., 'none')">none</xsl:when>
    </xsl:choose>
    <xsl:text>;</xsl:text>
  </xsl:attribute>
</xsl:template>

</xsl:stylesheet>
