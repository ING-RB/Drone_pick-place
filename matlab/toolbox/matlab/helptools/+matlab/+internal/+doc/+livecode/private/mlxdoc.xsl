<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE xsl:stylesheet [ <!ENTITY nbsp "&#160;"> ]>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" indent="no"/>
    
    <xsl:template match="/documentation">
        <html>
            <xsl:variable name="includes"><xsl:value-of select="includes" /></xsl:variable>
            <xsl:variable name="searchpage"><xsl:value-of select="searchpage" /></xsl:variable>
            <xsl:variable name="landingpage"><xsl:value-of select="landingpage" /></xsl:variable>
            <head>
                <title>
                    <xsl:choose>
                        <xsl:when test="/documentation[@release]">
                            <xsl:choose>
                                <xsl:when test="/documentation/method">
                                    <xsl:value-of select="//class_name"/>.<xsl:value-of select="//title"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="//title"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>

                        <!--Before 19a-->
                        <xsl:otherwise>
                            <xsl:value-of select="title" />
                        </xsl:otherwise>
                    </xsl:choose>
                </title>
                <link href="{$includes}/product/css/bootstrap.min.css" rel="stylesheet" type="text/css" />
                <link href="{$includes}/product/css/site6.css" rel="stylesheet" type="text/css" />
                <link href="{$includes}/product/css/site6_lg.css?201703160945" rel="stylesheet" media="screen and (min-width: 1200px)"></link>
                <link href="{$includes}/product/css/site6_md.css?201703160945" rel="stylesheet" media="screen and (min-width: 992px) and (max-width: 1199px)"></link>
                <link href="{$includes}/product/css/site6_sm+xs.css?201703160945" rel="stylesheet" media="screen and (max-width: 991px)"></link>
                <link href="{$includes}/product/css/site6_sm.css?201703160945" rel="stylesheet" media="screen and (min-width: 768px) and (max-width: 991px)"></link>
                <link href="{$includes}/product/css/site6_xs.css?201703160945" rel="stylesheet" media="screen and (max-width: 767px)"></link>
                <link href="{$includes}/product/css/doc_center_base.css" rel="stylesheet" type="text/css" />
                <link href="{$includes}/product/css/doc_center_installed.css" rel="stylesheet" type="text/css" />
                <script type="text/javascript" src="{$includes}/product/scripts/jquery/jquery-latest.js"></script>
                <script type="text/javascript" src="{$includes}/product/scripts/bootstrap.min.js"></script>
                <script type="text/javascript" src="{$includes}/product/scripts/global.js"></script>
                <script type="text/javascript" src="{$includes}/product/scripts/underscore-min.js"></script>
                <script type="text/javascript" src="{$includes}/product/scripts/suggest.js"></script>
                <script type="text/javascript" src="{$includes}/shared/scripts/helpservices.js"></script>
                <script type="text/javascript" src="{$includes}/shared/equationrenderer/release/MathRenderer.js"></script>
            </head>
            <body>
                <xsl:choose>
                    <xsl:when test="not($searchpage = '') and not($landingpage = '')">
                        <div class="sticky_header_container">
                            <div class="section_header level_3">
                              <div class="container-fluid">
                                <div class="row" id="mobile_search_row">
                                    <div class="col-xs-12 col-sm-6 col-md-7" id="section_header_title">
                                    <div class="section_header_content">
                                      <div class="section_header_title">
                                        <h1><a href="{$landingpage}">Documentation</a></h1>
                                      </div>                              
                                    </div>
                                  </div>
                                  <div class="col-xs-12 col-sm-6 col-md-5" id="mobile_search">
                                    <div class="search_nested_content_container">
                                      <form id="docsearch_form" name="docsearch_form" method="get" data-release="R2020a" data-language="en" action="{$searchpage}">
                                        <div class="input-group tokenized_search_field">
                                          <label class="sr-only">Search Documentation</label>
                                                        <input type="text" class="form-control conjoined_search" autocomplete="off" name="qdoc" placeholder="Search Documentation" id="docsearch"></input>
                                          <div class="input-group-btn">
                                            <button type="submit" name="submitsearch" id="submitsearch" class="btn icon-search btn_search_adjacent btn_search icon_16" tabindex="-1" disabled=""></button>
                                          </div>
                                        </div>
                                      </form>
                                    </div>
                                    <button class="btn icon-remove btn_search pull-right icon_32 visible-xs" data-toggle="collapse" href="#mobile_search" aria-expanded="false" aria-controls="mobile_search"></button>
                                  </div>
                                  <div class="visible-xs" id="search_actuator">
                                    <button class="btn icon-search btn_search pull-right icon_16" data-toggle="collapse" href="#mobile_search" aria-expanded="false" aria-controls="mobile_search"></button>
                                  </div>
                                </div>
                              </div>
                              <!--END.CLASS container-fluid--> 
                            </div>
                            <!--END.CLASS section_header level_3-->
                        </div><!--END.CLASS sticky_header_container-->
                    </xsl:when>
                </xsl:choose>



                <xsl:choose>
                <xsl:when test="/documentation[@release]">

                    <div class="content_container">
                        <div class="container-fluid">
                            <div class="row">
                                <div class="col-xs-12">
                                    <section id="doc_center_content">
                                        <div>
                                            <h1 class="r2019a">
                                                <xsl:choose>
                                                    <xsl:when test="/documentation/method">
                                                        <xsl:value-of select="//class_name"/>.<xsl:value-of select="//title"/>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:value-of select="//title"/>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </h1>

                                            <xsl:choose>
                                                <xsl:when test="/documentation/method">
                                                    <xsl:variable name="className">
                                                        <xsl:value-of select="//class_name"/>
                                                    </xsl:variable>
                                                    <p>
                                                        <b>Class: </b>
                                                        <a href="matlab:doc {$className}">
                                                            <xsl:value-of select="//class_name"/>
                                                        </a>
                                                    </p>
                                                </xsl:when>
                                            </xsl:choose>

                                            <div class="doc_topic_desc">
                                                <div class="purpose_container">
                                                    <p><xsl:value-of select="/documentation/*/purpose"/></p>
                                                </div>
                                            </div>
                                        </div>

                                        <xsl:choose>
                                            <xsl:when test="/documentation/function or /documentation/method">

                                                <div class="ref_sect">
                                                    <h2>Syntax</h2>
                                                    <div class="syntax_signature">
                                                        <div class="syntax_signature_module">
                                                            <xsl:apply-templates select="//syntaxes/syntax" />
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="ref_sect">
                                                    <h2 id="description">Description</h2>
                                                    <div class="descriptions">
                                                        <div class="description_module">
                                                            <div class="code_responsive">
                                                                <p><xsl:value-of select="/documentation/*/description" disable-output-escaping="yes"/></p>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </xsl:when>

                                        <xsl:when test="/documentation/classdef">

                                            <div class="refsummary">
                                                <h2>Description</h2>
                                                <xsl:value-of select="classdef/description" disable-output-escaping="yes"/>
                                            </div>
                                            <div class="ref_sect createobject">
                                                <h2>Creation</h2>
                                                <div class="ref_sect">
                                                    <h3>Syntax</h3>
                                                    <div class="syntax_signature">
                                                        <div class="syntax_signature_module">
                                                            <xsl:apply-templates select="//syntax_description/syntaxes/syntax"/>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="refsect2 description">
                                                    <h3>Description</h3>
                                                    <div class="description_module">
                                                        <div class="description_element">
                                                            <xsl:value-of select="//syntax_description/purpose" disable-output-escaping="yes"/>
                                                            <xsl:value-of select="//syntax_description/description" disable-output-escaping="yes"/>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="ref_sect">
                                                <h2>Properties</h2>
                                                <div class="doc_classesgroup_container">
                                                    <div class="table-responsive">
                                                        <table class="table table-bordered table-condensed">
                                                            <tbody>
                                                                <xsl:for-each select="//properties/property">
                                                                    <tr>
                                                                        <td class="term notranslate"><xsl:value-of select="title"/></td>
                                                                        <td class="description">
                                                                            <xsl:value-of select="purpose"/>
                                                                            <div><xsl:value-of select="description" disable-output-escaping="yes"/></div>
                                                                        </td>
                                                                    </tr>
                                                                </xsl:for-each>
                                                            </tbody>
                                                        </table>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="refsect1 objectfunctions">
                                                <h2>Object Functions</h2>
                                                <div class="doc_classesgroup_container">
                                                    <div class="table-responsive">
                                                        <table class="table table-bordered table-condensed">
                                                            <tbody>
                                                                <xsl:for-each select="//methods/method">
                                                                    <tr>
                                                                        <td class="term notranslate">
                                                                            <xsl:variable name="topic"><xsl:value-of select="//title"/></xsl:variable>
                                                                            <xsl:variable name="methodName"><xsl:value-of select="title"/></xsl:variable>
                                                                            <a href="matlab:doc {$topic}/{$methodName}">
                                                                                <xsl:value-of select="title"/>
                                                                            </a>
                                                                        </td>
                                                                        <td class="description"><xsl:value-of select="purpose"/></td>
                                                                    </tr>
                                                                </xsl:for-each>
                                                            </tbody>
                                                        </table>
                                                    </div>
                                                </div>
                                            </div>
                                        </xsl:when>
                                        </xsl:choose>

                                    </section>
                                </div>
                            </div>
                        </div>
                    </div>

                </xsl:when>


                <!--Before 19a-->
                <xsl:otherwise>
                    <div class="content_container">
                        <div class="container-fluid">
                            <div class="row">
                                <div class="col-xs-12">
                                    <section id="doc_center_content">
                                        <div>
                                            <h1 class="r2017a"><xsl:value-of select="title" /></h1>
                                            <div class="doc_topic_desc">
                                                <div class="purpose_container">
                                                    <p><xsl:value-of select="purpose" /></p>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="ref_sect">
                                            <h2>Syntax</h2>
                                            <div class="syntax_signature">
                                                <div class="syntax_signature_module">
                                                    <xsl:apply-templates select="syntaxes/syntax" />
                                                </div>
                                            </div>
                                        </div>

                                        <div class="ref_sect">
                                            <h2 id="description">Description</h2>
                                            <div class="descriptions">
                                                <div class="description_module">
                                                    <div class="code_responsive">
                                                        <p>
                                                            <xsl:value-of select="description" disable-output-escaping="yes"/>
                                                        </p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </section>
                                </div>
                            </div>
                        </div>
                    </div>
                </xsl:otherwise>
                </xsl:choose>

            </body>
        </html>
    </xsl:template>

    <xsl:template match="syntax">
        <div class="code_responsive"><code class="synopsis"><xsl:value-of select="." /></code></div>
    </xsl:template>
</xsl:transform>
