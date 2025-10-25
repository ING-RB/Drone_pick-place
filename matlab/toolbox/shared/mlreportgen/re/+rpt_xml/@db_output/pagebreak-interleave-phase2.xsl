<?xml version="1.0"?>
<!-- Copyright 2024 The MathWorks, Inc. -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                version="1.0">

<!-- Copyright MathWorks, Inc. 2016 -->

<!-- Remove fo:flow elment that contains rg-delete-page -->

    <xsl:template match="node()|@*">
      <xsl:copy>
         <xsl:apply-templates select="node()|@*"/>
      </xsl:copy>
    </xsl:template>

    <xsl:template match="fo:page-sequence[descendant::rg-delete-page]"/>
    
</xsl:stylesheet>
