<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
<!ENTITY nl "&#10;">
<!ENTITY nbsp "&#160;">  ]>
<!-- Copyright 2010-2022 The MathWorks, Inc. -->

<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:matfilecomparison="https://www.mathworks.com/matfilecomparison">    
    <xsl:output method="html" encoding="UTF-8" media-type="text/html" indent="yes"/>
    <!-- Should the merge functionality be enabled -->
    <xsl:param name ="mergingEnabled">
        <xsl:value-of select="/MatFileEditScript/@mergingEnabled"/>
    </xsl:param>
    <!-- Colors to be used for variables in various states -->
    <xsl:param name="backgroundcolor">
         <xsl:value-of select="/MatFileEditScript/@backgroundColor"/>
    </xsl:param> 

    <!-- Root element. -->
    <xsl:template match="MatFileEditScript">
        <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html&gt;</xsl:text>
        <html>
            <head>
                <title>Comparison Tool</title>
                <!-- Only include the following bundles for the Java tool. Otherwise, errors flood the console. -->
                <!-- <script type="text/javascript" src="/toolbox/shared/comparisons/web/mw-diff/release/mw-diff/dojoConfig-release-global.js"></script> -->
                <!-- <script type="text/javascript" src="/toolbox/shared/comparisons/web/mw-diff/release/bundle.index.js"></script> -->
                <!-- See "root.setAttribute('bundles', bundles)" in matdiff.m -->
                <xsl:value-of select="/MatFileEditScript/@bundles" disable-output-escaping="yes"/>
                <script type="text/javascript" src="/toolbox/shared/comparisons/web/templates/shared/js/printablereport.js"></script>
                <script type="text/javascript" src="/toolbox/shared/comparisons/web/templates/shared/js/sorttable.js"></script>
                <script type="text/javascript" src="/toolbox/shared/comparisons/web/templates/shared/js/events.js"></script>
                <script language="javascript">
                    var REPORT_ID = &quot;<xsl:value-of select="/MatFileEditScript/@id"/>&quot;;
                    var LEFT_FILE = &quot;<xsl:value-of select="LeftLocation/@ReadableNeutral"/>&quot;;
                    var RIGHT_FILE = &quot;<xsl:value-of select="RightLocation/@ReadableNeutral"/>&quot;;
                </script>
                <script type="text/javascript" src="/toolbox/shared/comparisons/web/templates/mat/js/matdiff.js"></script>
                <style type="text/css">
                    td, th {
                        padding-left: 5px;
                        padding-right: 5px;
                        padding-top: 2px;
                        padding-bottom: 2px;
                        border-right: 1px;
                        border-top: #777777 1px solid;
                        border-left: #777777 1px solid;
                        border-bottom: 1px;
                    }

                    table {
                        border-spacing: 0px;
                        border-right: #777777 1px solid;
                        border-bottom: #777777 1px solid;
                    }

                    img.merge {
                        cursor: pointer;
                    }

                    img.compare {
                        cursor: pointer;
                    }

                    span.action {
                        color: blue;
                        cursor: pointer;
                        text-decoration: underline;
                    }
                </style>
                <style>
                    <!-- Placed in own style tag to avoid css being printed in HTML report -->
                    <xsl:value-of select="/MatFileEditScript/@FindCSS"/>
                </style>
            </head>
            <body class="matcomparisonreport">
                <xsl:attribute name="style">
                    background: <xsl:value-of select="$backgroundcolor"/>
                </xsl:attribute>
                <!-- Title, file names and header text -->
                <h2>
                    <xsl:value-of select="/MatFileEditScript/@reportTitle" disable-output-escaping="yes"/>
                </h2>
                <table id="files" cellspacing="0">
                    <tr>
                        <td>
                            <b><xsl:value-of select="/MatFileEditScript/@LeftFileMsg"/></b>
                        </td>
                        <td>
                            <code><xsl:value-of select="LeftLocation"/></code>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <b><xsl:value-of select="/MatFileEditScript/@RightFileMsg"/></b>
                        </td>
                        <td>
                            <code><xsl:value-of select="RightLocation"/></code>
                        </td>
                    </tr>
                </table>
                <p/>
                <p>
                    <xsl:choose>
                        <xsl:when test="@difftype='container' or @difftype='format'">
                            <xsl:choose>
                                <xsl:when test="@difftype='format'">
                                    <xsl:value-of select="/MatFileEditScript/@FormatDifferenceOnlyMsg" disable-output-escaping="yes"/>
                                </xsl:when>
                                <xsl:when test="@difftype='container'">
                                    <xsl:value-of select="/MatFileEditScript/@ContainerDifferenceOnlyMsg" disable-output-escaping="yes"/>
                                </xsl:when>
                            </xsl:choose>
                            <br/>
                            <span class="action">
                                <xsl:attribute name="id">ComparingMATFilesLink</xsl:attribute>
                                <xsl:attribute name="onclick">MATLABEval('helpview(fullfile(docroot, \'/matlab/matlab_env/matlab_env.map\'), \'matlab_env_matcomparison\')')</xsl:attribute>
                                <xsl:value-of select="/MatFileEditScript/@LearnMoreTitle" disable-output-escaping="yes"/>
                            </span>
                        </xsl:when>
                        <xsl:when test="@difftype='identical'">
                            <xsl:value-of select="/MatFileEditScript/@IdenticalFilesMsg" disable-output-escaping="yes"/>
                        </xsl:when>
                   </xsl:choose>
                </p>
                <!-- Table of variables -->
                <em id="clicktosort">
                    <xsl:value-of select="/MatFileEditScript/@clickToSort"/>
                </em>
                <table class="sortable" id="varlist" cellspacing="0">
                    <thead>
                        <tr>
                            <th colspan="3">
                                <xsl:value-of select="LeftLocation/@ColumnHeader" disable-output-escaping="yes"/>
                            </th>
                            <th colspan="3">
                                <xsl:value-of select="RightLocation/@ColumnHeader" disable-output-escaping="yes"/>
                            </th>
                            <th colspan="2">&nbsp;</th>
                        </tr>
                        <tr style="background: #EEE">
                            <th>
                                <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                                <xsl:value-of select="/MatFileEditScript/@VarNameMsg"/>
                            </th>
                            <th>
                                <xsl:attribute name="class">sorttable_numeric</xsl:attribute>
                                <xsl:value-of select="/MatFileEditScript/@SizeMsg"/>
                            </th>
                            <th>
                                <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                                <xsl:value-of select="/MatFileEditScript/@ClassMsg"/>
                            </th>
                            <th>
                                <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                                <xsl:value-of select="/MatFileEditScript/@VarNameMsg"/>
                            </th>
                            <th>
                                <xsl:attribute name="class">sorttable_numeric</xsl:attribute>
                                <xsl:value-of select="/MatFileEditScript/@SizeMsg"/>
                            </th>
                            <th>
                                <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                                <xsl:value-of select="/MatFileEditScript/@ClassMsg"/>
                            </th>
                            <th>
                                <xsl:attribute name="class">sorttable_alpha</xsl:attribute>
                                <xsl:value-of select="/MatFileEditScript/@StatusMsg"/>
                            </th>
                            <xsl:choose>
                                <xsl:when test="$mergingEnabled='true'">
                                    <th>
                                        <xsl:value-of select="/MatFileEditScript/@ActionMsg"/>
                                    </th>
                                </xsl:when>
                            </xsl:choose>   
                        </tr>
                    </thead>
                    <tbody>
                        <xsl:apply-templates mode="full"/>
                    </tbody>
                </table>
                <p/>
                <!-- Hyperlinks for loading the file contents -->
                <p>
                    <span class="action">
                        <xsl:attribute name="id">leftLoadFileLink</xsl:attribute>
                        <xsl:attribute name="onclick">MATLABEval('uiopen(\'' + LEFT_FILE + '\', 1)')</xsl:attribute>
                        <xsl:value-of select="LeftLocation/@leftLoadFileLinkMessage" disable-output-escaping="yes"/>
                    </span>
                    <br/>
                    <span class="action">
                        <xsl:attribute name="id">rightLoadFileLink</xsl:attribute>
                        <xsl:attribute name="onclick">MATLABEval('uiopen(\'' + RIGHT_FILE + '\', 1)')</xsl:attribute>
                        <xsl:value-of select="RightLocation/@rightLoadFileLinkMessage" disable-output-escaping="yes"/>
                    </span>
                </p>
                <xsl:choose>
                    <xsl:when test="LeftLocation/@Backup">
                        <p>
                            <xsl:value-of select="LeftLocation/@CEFRestoreFromBackupMsg" disable-output-escaping="yes"/>
                        </p>
                    </xsl:when>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="RightLocation/@Backup">
                        <p>
                            <xsl:value-of select="RightLocation/@CEFRestoreFromBackupMsg" disable-output-escaping="yes"/>
                        </p>
                    </xsl:when>
                </xsl:choose>
                <script language="javascript">
                    <!-- This is deliberately positioned at the very end of the page. -->
                    sorttable.init();
                </script>
            </body>
        </html>
    </xsl:template>
    <xsl:template match="LeftLocation" mode="full">
        <!-- This information was already printed in the EditScript template above-->
    </xsl:template>
    <xsl:template match="RightLocation" mode="full">
        <!-- This information was already printed in the EditScript template above-->
    </xsl:template>
    <xsl:template match="Title" mode="full">
        <!-- This information was already printed in the EditScript template above-->
    </xsl:template>
    <!-- Generate hyperlink for opening a specific variable -->
    <xsl:template name="openhyperlink">
        <xsl:param name="side">must be specified!</xsl:param>
        <xsl:param name="name">must be specified!</xsl:param>
        <span class="action">
            <xsl:attribute name="onclick">openvar('<xsl:value-of select="$side"/>','<xsl:value-of select="$name"/>')</xsl:attribute>
            <xsl:value-of select="$name"/>
        </span>
    </xsl:template>
    <!-- Generate hyperlinks for merging a variable from right to left -->
    <xsl:template name="mergeleftlink">
        <xsl:param name="name">must be specified!</xsl:param>
        <xsl:variable name="arrowfile">/toolbox/shared/comparisons/web/templates/mat/images/varmergeleft.png</xsl:variable>
        <img class="merge">
            <xsl:attribute name="src"><xsl:value-of select="$arrowfile"/></xsl:attribute>
            <xsl:attribute name="onclick">mergeleft('<xsl:value-of select="$name"/>')</xsl:attribute>
            <xsl:attribute name="title"><xsl:value-of select="/MatFileEditScript/@mergeLeftLinkTitle" disable-output-escaping="yes"/></xsl:attribute>
        </img>
    </xsl:template>
    <xsl:template name="deleteleftlink">
        <xsl:param name="name">must be specified!</xsl:param>
        <xsl:variable name="arrowfile">/toolbox/shared/comparisons/web/templates/mat/images/vardelete.png</xsl:variable>
        <img class="merge">
            <xsl:attribute name="src"><xsl:value-of select="$arrowfile"/></xsl:attribute>
            <xsl:attribute name="onclick">mergeleft('<xsl:value-of select="$name"/>')</xsl:attribute>
            <xsl:attribute name="title"><xsl:value-of select="/MatFileEditScript/@deleteLeftLinkTitle" disable-output-escaping="yes"/></xsl:attribute>
        </img>
    </xsl:template>
    <!-- Generate hyperlinks for merging a variable from left to right -->
    <xsl:template name="mergerightlink">
        <xsl:param name="name">must be specified!</xsl:param>
        <xsl:variable name="arrowfile">/toolbox/shared/comparisons/web/templates/mat/images/varmergeright.png</xsl:variable>
        <img class="merge">
            <xsl:attribute name="src"><xsl:value-of select="$arrowfile"/></xsl:attribute>
            <xsl:attribute name="onclick">mergeright('<xsl:value-of select="$name"/>')</xsl:attribute>
            <xsl:attribute name="title"><xsl:value-of select="/MatFileEditScript/@mergeRightLinkTitle" disable-output-escaping="yes"/></xsl:attribute>
        </img>
    </xsl:template>
    <xsl:template name="deleterightlink">
        <xsl:param name="name">must be specified!</xsl:param>
        <xsl:variable name="arrowfile">/toolbox/shared/comparisons/web/templates/mat/images/vardelete.png</xsl:variable>
        <img class="merge">
            <xsl:attribute name="src"><xsl:value-of select="$arrowfile"/></xsl:attribute>
            <xsl:attribute name="onclick">mergeright('<xsl:value-of select="$name"/>')</xsl:attribute>
            <xsl:attribute name="title"><xsl:value-of select="/MatFileEditScript/@deleteRightLinkTitle" disable-output-escaping="yes"/></xsl:attribute>
        </img>
    </xsl:template>
    <!-- Generate hyperlinks for comparing two variables -->
    <xsl:template name="comparelink">
        <xsl:param name="name">must be specified!</xsl:param>
        <xsl:param name="string"><xsl:value-of select="/MatFileEditScript/@compareLinkText"/></xsl:param>
        <span class="action">
            <xsl:attribute name="title"><xsl:value-of select="/MatFileEditScript/@compareVarsMessage" disable-output-escaping="yes"/></xsl:attribute>
            <xsl:attribute name="onclick">comparevar('<xsl:value-of select="$name"/>')</xsl:attribute>
            <xsl:value-of select="$string"/>
        </span>
    </xsl:template>
    <!-- A file which appears in the left list only -->
    <xsl:template match="LeftVariable" mode="full">
        <tr>
            <xsl:attribute name="id">
                <xsl:value-of select="."/>
            </xsl:attribute>
            <td class="var">
                <xsl:attribute name="style">background:<xsl:value-of select="@contentsColor"/></xsl:attribute>
                <xsl:call-template name="openhyperlink">
                    <xsl:with-param name="side">left</xsl:with-param>
                    <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                </xsl:call-template>
            </td>
            <td class="var">
                <xsl:attribute name="style">background:<xsl:value-of select="@contentsColor"/></xsl:attribute>
                <xsl:value-of select="@size"/>
            </td>
            <td>
                <xsl:attribute name="class">var</xsl:attribute>
                <xsl:attribute name="style">background:<xsl:value-of select="@contentsColor"/></xsl:attribute>
                <xsl:value-of select="@class"/>
            </td>
            <td colspan="3" class="var">
                <xsl:value-of select="@tableSummary" disable-output-escaping="yes"/>
            </td>
            <td class="var">
                <xsl:attribute name="style">background:<xsl:value-of select="@contentsColor"/></xsl:attribute>
                <xsl:value-of select="@statusSummary" disable-output-escaping="yes"/>
            </td>
            <xsl:choose>
                <xsl:when test="$mergingEnabled='true'">
                    <xsl:choose>
                        <xsl:when test="$mergingEnabled='true'">
                            <td align="left">
                                <xsl:call-template name="deleteleftlink">
                                    <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                                </xsl:call-template>
                                <xsl:call-template name="mergerightlink">
                                    <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                                </xsl:call-template>
                            </td>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>   
        </tr>
    </xsl:template>
    <!-- A file which appears in the right list only -->
    <xsl:template match="RightVariable" mode="full">
        <tr>
            <xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
            <td colspan="3" class="var">
                <xsl:value-of select="@tableSummary" disable-output-escaping="yes"/>
            </td>
            <td class="var">
                <xsl:attribute name="style">background:<xsl:value-of select="@contentsColor"/></xsl:attribute>
                <xsl:call-template name="openhyperlink">
                    <xsl:with-param name="side">right</xsl:with-param>
                    <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                </xsl:call-template>
            </td>
            <td class="var">
                <xsl:attribute name="style">background:<xsl:value-of select="@contentsColor"/></xsl:attribute>
                <xsl:value-of select="@size"/>
            </td>
            <td class="var">
                <xsl:attribute name="style">background:<xsl:value-of select="@contentsColor"/></xsl:attribute>
                <xsl:value-of select="@class"/>
            </td>
            <td class="var">
                <xsl:attribute name="style">background:<xsl:value-of select="@contentsColor"/></xsl:attribute>
                <xsl:value-of select="@statusSummary" disable-output-escaping="yes"/>
            </td>
            <xsl:choose>
                <xsl:when test="$mergingEnabled='true'">
                    <xsl:choose>
                        <xsl:when test="$mergingEnabled='true'">
                            <td align="left">
                                <xsl:call-template name="mergeleftlink">
                                    <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                                </xsl:call-template>
                                <xsl:call-template name="deleterightlink">
                                    <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                                </xsl:call-template>
                            </td>
                        </xsl:when>
                    </xsl:choose>   
                </xsl:when>
            </xsl:choose>   
        </tr>
    </xsl:template>
    <!-- A variable which appears in both columns.  The value of the "contentsMatch"
         attribute determines what we need to display. -->
    <xsl:template match="Variable" mode="full">
        <xsl:variable name="color"><xsl:value-of select="@contentsColor"/></xsl:variable>
        <tr>
            <xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
            <xsl:attribute name="style">background:<xsl:value-of select="$color"/></xsl:attribute>
            <!-- Name -->
            <td class="var">
                <xsl:attribute name="style">background:<xsl:value-of select="$color"/></xsl:attribute>
                <xsl:call-template name="openhyperlink">
                    <xsl:with-param name="side">left</xsl:with-param>
                    <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                </xsl:call-template>
            </td>
            <!-- Left size -->
            <td class="var">
                <xsl:attribute name="style">background:<xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="@leftsize"/>
            </td>
            <!-- Left class -->
            <td class="var">
                <xsl:choose>
                    <xsl:when test="@contentsMatch='classesdiffer'">
                       <xsl:attribute name="style">background:<xsl:value-of select="/MatFileEditScript/@ChangedColor"/></xsl:attribute> 
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="style">background:<xsl:value-of select="$color"/></xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="@leftclass"/>
            </td>
            <!-- Name again (hyperlink to open the right-hand variable -->
            <td class="var">
                <xsl:attribute name="style">background:<xsl:value-of select="$color"/></xsl:attribute>
                <xsl:call-template name="openhyperlink">
                    <xsl:with-param name="side">right</xsl:with-param>
                    <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                </xsl:call-template>
            </td>
            <!-- Right size -->
            <td class="var">
                <xsl:attribute name="style">background:<xsl:value-of select="$color"/></xsl:attribute>
                <xsl:value-of select="@rightsize"/>
            </td>
            <!-- Right class -->
            <td class="var">
                <xsl:choose>
                    <xsl:when test="@contentsMatch='classesdiffer'">
                        <xsl:attribute name="style">background:<xsl:value-of select="/MatFileEditScript/@ChangedColor"/></xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="style">background:<xsl:value-of select="$color"/></xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="@rightclass"/>
            </td>
            <!-- Status -->
            <td class="var">
                <xsl:attribute name="style">background:<xsl:value-of select="$color"/></xsl:attribute>
                <xsl:choose>
                    <xsl:when test="@contentsMatch='yes'">
                        <xsl:value-of select="@statusSummary" disable-output-escaping="yes"/>
                    </xsl:when>
                    <xsl:when test="@contentsMatch='no'">
                        <xsl:value-of select="@statusSummary" disable-output-escaping="yes"/>
                        <xsl:call-template name="comparelink">
                            <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="@contentsMatch='classesdiffer'">
                        <xsl:value-of select="/MatFileEditScript/@classesDifferText" disable-output-escaping="yes"/>
                        <xsl:call-template name="comparelink">
                            <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                        </xsl:call-template>
                    </xsl:when>
                </xsl:choose>
            </td>
            <xsl:choose>
                <xsl:when test="$mergingEnabled='true'">
                    <td>
                        <xsl:choose>
                            <xsl:when test="@contentsMatch='yes'">&nbsp;</xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="mergeleftlink">
                                    <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                                </xsl:call-template>
                                <xsl:call-template name="mergerightlink">
                                    <xsl:with-param name="name"><xsl:value-of select="."/></xsl:with-param>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </td>
                </xsl:when>
            </xsl:choose>   
        </tr>
    </xsl:template>
</xsl:stylesheet>
