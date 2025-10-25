<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" version="1.0">
	<xsl:template match="@*|node()">
    	<xsl:copy>
    		<xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    <!--xsl:template match="//*[@*[namespace='']]"/-->
</xsl:stylesheet>