<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ng="http://docbook.org/docbook-ng"
                xmlns:db="http://docbook.org/ns/docbook"
                xmlns:exsl="http://exslt.org/common"
                xmlns:exslt="http://exslt.org/common"
                exclude-result-prefixes="db ng exsl exslt"
                version='1.0'>

<xsl:import href="docbook.xsl"/>

<xsl:output method="html" encoding="UTF-8" indent="no"/>
            
<xsl:include href="mcode.xsl"/>              


<!-- Post convert import action -->
<xsl:template match="rptgen:importpost" xmlns:rptgen="http://www.mathworks.com/namespace/rptgen/import/v1">
    <xsl:choose>
        <xsl:when test="contains(@url,'.htm')">
            -rG-ImPoRt-BeGiN-
            <xsl:value-of select="@url"/>
            -Rg-iMpOrT-eNd-
        </xsl:when>
        <xsl:otherwise>
            <!--   <xsl:call-template name="ulink"/>  -->
            <a>
                <xsl:attribute name="href">
                    <xsl:value-of select="@url"/>
                </xsl:attribute>
                <xsl:if test="$ulink.target != ''">
                    <xsl:attribute name="target">
                        <xsl:value-of select="$ulink.target"/>
                    </xsl:attribute>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="count(child::node())=0">
                        <xsl:value-of select="@url"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates/>
                    </xsl:otherwise>
                </xsl:choose>
            </a>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<!-- @ENDCHANGE -->

<!-- * @CHANGE
     * Report generator files may use xsl:import to signal that an
     * external file should be loaded in that place.  We do this instead
     * of using entity references because entities are not handled well
     * by DOM level 2.  Perhaps when we cut over to DOM 3 we will use them.
     * -->
<xsl:template match="xsl:include">
  <xsl:copy-of select="document(@href)"/>
  <xsl:apply-templates/>
</xsl:template>
<!-- @ENDCHANGE -->
            
</xsl:stylesheet>

            