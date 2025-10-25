<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                xmlns:fox="http://xml.apache.org/fop/extensions"
                xmlns="http://www.w3.org/TR/xhtml1/transitional" 
                xmlns:exsl="http://exslt.org/common" 
                exclude-result-prefixes="xsl" 
                version="1.0">

  <xsl:import href="docbook.xsl"/>
    
  <!-- MATLAB code support -->
  <xsl:include href="mcode.xsl"/>  
    
  <!-- Hard page break support (used by custom components that creates this PI) --> 
  <xsl:template match="processing-instruction('hard-pagebreak')">
    <fo:block break-before='page'/>
  </xsl:template>
    
  <!-- Post convert import action -->
  <xsl:template match="rptgen:importpost" 
                xmlns:rptgen="http://www.mathworks.com/namespace/rptgen/import/v1">
    <fo:block xsl:use-attribute-sets="normal.para.spacing">
            
      <!-- Use @fileRef when we are linking  
           Acrobat does not like referring to external docs as URI. -->
      <xsl:variable name ="linkid">
        <xsl:choose>
          <xsl:when test="@fileRef">
            <xsl:value-of select="@fileRef"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@url"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
            
      <!-- Based on ULINK template -->
      <fo:basic-link xsl:use-attribute-sets="xref.properties"
                     external-destination="{$linkid}">
        <xsl:choose>
          <xsl:when test="count(child::node())=0">
            <xsl:call-template name="hyphenate-url">
              <xsl:with-param name="url" select="$linkid"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates/>
          </xsl:otherwise>
        </xsl:choose>
      </fo:basic-link>
            
            <xsl:if test="count(child::node()) != 0 
                          and string(.) != $linkid 
                          and $ulink.show != 0">
                <!-- yes, show the URI -->
                <xsl:choose>
                    <xsl:when test="$ulink.footnotes != 0 and not(ancestor::footnote)">
                        <fo:footnote>
                            <xsl:call-template name="ulink.footnote.number"/>
                            <fo:footnote-body xsl:use-attribute-sets="footnote.properties">
                                <fo:block>
                                    <xsl:call-template name="ulink.footnote.number"/>
                                    <xsl:text> </xsl:text>
                                    <fo:basic-link external-destination="{$linkid}">
                                        <xsl:value-of select="$linkid"/>
                                    </fo:basic-link>
                                </fo:block>
                            </fo:footnote-body>
                        </fo:footnote>
                    </xsl:when>
                    <xsl:otherwise>
                        <fo:inline hyphenate="false">
                            <xsl:text> [</xsl:text>
                            <fo:basic-link external-destination="{$linkid}">
                                
                                <!-- replace %20 with a blank space, to look better -->
                                <xsl:call-template name="string.subst">
                                    <xsl:with-param name="string" select="$linkid"/>
                                    <xsl:with-param name="target" select="'%20'"/>
                                    <xsl:with-param name="replacement" select="' '"/>
                                </xsl:call-template>
                                
                            </fo:basic-link>
                            <xsl:text>]</xsl:text>
                        </fo:inline>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </fo:block>
    </xsl:template>

</xsl:stylesheet>