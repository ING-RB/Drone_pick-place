<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!--
     Copyright 1997-2002 The MathWorks, Inc. 
       
     
     This XSL stylesheet file is intended for use with Report Generator
     component registry files, typically named rptcomponents.xml
-->

<xsl:template match="*|/"><xsl:apply-templates/></xsl:template>

<xsl:template match="text()|@*"><xsl:value-of select="."/></xsl:template>

<xsl:template match="*|/"><html><body>
<h2>All Components</h2>
<ul>
<xsl:for-each select="descendant::c">
<li><xsl:apply-templates/></li>
</xsl:for-each>
</ul>
</body></html></xsl:template>

</xsl:stylesheet>
