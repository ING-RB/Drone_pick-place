<?xml version="1.0"?>
<!-- Copyright 2024 The MathWorks, Inc. -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                version="1.0">

<!-- Copyright MathWorks, Inc. 2016 -->

<!-- This file contains the logic for inserting page breaks at arbitrary locations.  
        During a post-processing phase, it finds the instances of rg-page-break and 
        appropriately closes all open tags, inserts a page-sequence and reopens all
        closed tags as needed. -->

<!-- ==================================================================== -->

    <!-- Identity transform -->
    <xsl:template match="node()|@*">
      <xsl:copy>
         <xsl:apply-templates select="node()|@*"/>
      </xsl:copy>
    </xsl:template>

    <!-- Insert custom page breaks to interleave different page sizing information-->    
    <xsl:template match="rg-page-break">
        <!-- Before inserting another page-sequence, we need to close all open XML tags up to the previous page-sequence -->
        <xsl:choose>
            <!-- If preceding sibling was a "rg-page-break", then just manually close the custom tags -->
            <xsl:when test="name(preceding-sibling::*[position()=1]) = 'rg-page-break'">
                <xsl:call-template name="write-close-tag">
                    <xsl:with-param name="tag-name" select="'fo:flow'"/>
                </xsl:call-template>

                <xsl:call-template name="write-close-tag">
                    <xsl:with-param name="tag-name" select="'fo:page-sequence'"/>
                </xsl:call-template>
            </xsl:when>
            <!-- close ancestors -->
            <xsl:otherwise>
                <xsl:call-template name="close-all-ancestors">
                    <xsl:with-param name="current-node" select=".."/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>

        <!-- Write the new fo:page-sequence (need to do this manually since we may not necessarily be closing it in this function) -->
        <xsl:call-template name="write-custom-open-tag">
            <xsl:with-param name="tag-name-and-attributes">
                <xsl:text disable-output-escaping="yes">fo:page-sequence master-reference="</xsl:text>
                <xsl:value-of select="@master-reference"/>
                <xsl:text disable-output-escaping="yes">"</xsl:text>
            </xsl:with-param>
        </xsl:call-template>

        <!-- Manually open the new fo:flow tag -->
        <xsl:call-template name="write-custom-open-tag">
            <xsl:with-param name="tag-name-and-attributes">
                <xsl:text disable-output-escaping="yes">fo:flow flow-name="xsl-region-body"</xsl:text>
            </xsl:with-param>
        </xsl:call-template>

        <!-- Copy content inside rg-page-break -->
        <xsl:apply-templates/>

        <!-- If there is no further content for the previous page "../following-sibling::*" and the following
             sibiling is a "rg-page-break", don't bother closing and reopening the flow and page-sequence, 
             they'll take care of themselves.  -->
        <xsl:if test="name(following-sibling::*[position()=1]) != 'rg-page-break'">
            <xsl:call-template name="write-close-tag">
                <xsl:with-param name="tag-name" select="'fo:flow'"/>
            </xsl:call-template>

            <xsl:call-template name="write-close-tag">
                <xsl:with-param name="tag-name" select="'fo:page-sequence'"/>
            </xsl:call-template>

            <!-- Set the XML back to the state it was in before the new page -->
            <xsl:call-template name="reopen-all-ancestors">
                <xsl:with-param name="current-node" select=".."/>
            </xsl:call-template>
            
            <!-- If we interleave at the end, an extra page will be created in order to produce
                 a well formed document.  Mark it so we can delete this extra page in phase 2 -->
            <xsl:if test="not(following::*)">
                <rg-delete-page/>
            </xsl:if>
        </xsl:if>    
    </xsl:template>
    
    <!-- Iterates up the ancestor axis and closes all open XML tags up to and including the last page-sequence -->
    <xsl:template name="close-all-ancestors">
        <xsl:param name="current-node"/>

        <xsl:variable name="node-name" select="name($current-node)"/>

        <!-- If there is no node name, we've likely recursed right out of the document -->
        <xsl:if test="$node-name != ''">
            <xsl:call-template name="write-close-tag">
                <xsl:with-param name="tag-name" select="$node-name"/>
            </xsl:call-template>

            <!-- Recurse up the ancestor tree -->
            <xsl:if test="$node-name != 'fo:page-sequence'">
                <xsl:call-template name="close-all-ancestors">
                    <xsl:with-param name="current-node" select="$current-node/.."/>
                </xsl:call-template>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- Iterates up the ancestor axis and reopens all XML tags up to and including the last page-sequence -->
    <xsl:template name="reopen-all-ancestors">
        <xsl:param name="current-node"/>

        <xsl:variable name="node-name" select="name($current-node)"/>

        <xsl:if test="$node-name != ''">
            <xsl:if test="$node-name != 'fo:page-sequence'">
                <xsl:call-template name="reopen-all-ancestors">
                    <xsl:with-param name="current-node" select="$current-node/.."/>
                </xsl:call-template>
            </xsl:if>

            <xsl:call-template name="write-open-tag">
                <xsl:with-param name="original-tag" select="$current-node"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- Close the given tag -->
    <xsl:template name="write-close-tag">
        <xsl:param name="tag-name"/>

        <!-- NOTE: cannot simply write a close tag as that would make this stylesheet into invalid XML; instead, manually write the brackets -->
        <xsl:text disable-output-escaping="yes">&lt;/</xsl:text>
        <xsl:value-of select="$tag-name"/>
        <xsl:text disable-output-escaping="yes">&gt;</xsl:text>
    </xsl:template>

    <!-- Reopen the given tag (and copy all attributes with it -->
    <xsl:template name="write-open-tag">
        <xsl:param name="original-tag"/>

        <!-- NOTE: cannot simply write an open tag as that would make this stylesheet into invalid XML; instead, manually write the brackets and attributes -->
        <xsl:text disable-output-escaping="yes">&lt;</xsl:text>
        <xsl:value-of select="name($original-tag)"/>
            <!-- skip copying page number attribute -->
            <xsl:for-each select="$original-tag/@*[not(name(.)='initial-page-number')]">
                <xsl:text> </xsl:text><xsl:value-of select="name(.)"/><xsl:text>="</xsl:text><xsl:value-of select="."/><xsl:text>" </xsl:text>
            </xsl:for-each>
        <xsl:text disable-output-escaping="yes">&gt;</xsl:text>
        
        <!-- Copy headers and footers -->
        <xsl:copy-of select="$original-tag/fo:static-content"/>
    </xsl:template>

    <!-- Open the given tag name -->
    <xsl:template name="write-custom-open-tag">
        <xsl:param name="tag-name-and-attributes"/>

        <!-- NOTE: cannot simply write a close tag as that would make this stylesheet into invalid XML; instead, manually write the brackets -->
        <xsl:text disable-output-escaping="yes">&lt;</xsl:text>
        <xsl:value-of select="$tag-name-and-attributes"/>
        <xsl:text disable-output-escaping="yes">&gt;</xsl:text>
    </xsl:template>

</xsl:stylesheet>
