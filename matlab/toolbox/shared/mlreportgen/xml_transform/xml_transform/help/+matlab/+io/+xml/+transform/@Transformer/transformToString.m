%transformToString Transform an XML document into a string
%    string = transformToString(transformer,input,stylesheet) transforms
%    the specified input document, using the specified stylesheet, and
%    returns the result as a string scalar.  See the table below
%    for the input argument data types accepted by this method.
%
%    string = transformToString(transformer,input) transforms the specified
%    input document, using the specified stylesheet, and returns the result
%    as a string scalar.  This method requires that the input document
%    contain a processing instruction that specifies the stylesheet to be
%    used to transform the document.  For example, the following lines
%    begin an XML document that specifies use of a stylesheet named
%    "catalog.xsl" located in the current working directory.
%     
%     <?xml version="1.0" encoding="UTF-8"?>
%     <?xml-stylesheet type="text/xsl" href="catalog.xsl"?>
%
%     See the table below for the argument data types accepted by this
%     method.
%
%    The following table summarizes the data types that can be used to 
%    specify transform argument values:
%
%    Argument    Value               Data Type
%    ======================================================================
%    transformer transformer         matlab.io.xml.transform.Transformer
%   
%    input      XML file path        - string scalar
%                                     - character vector
%                                     - matlab.io.xml.transform.SourceFile
%
%    input      XML string           - matlab.io.xml.transform.SourceString
%
%    input      Parsed XML document  - matlab.io.xml.dom.Document
%                                    - matlab.io.xml.transform.SourceDocument
%
%    stylesheet XML file path        - string scalar
%                                    - character vector
%                                    - matlab.io.xml.transform.StylesheetSourceFile
%
%    stylesheet XML string           - matlab.io.xml.transform.StylesheetSourceString
%
%    stylesheet Parsed XML document  - matlab.io.xml.dom.Document
%                                    - matlab.io.xml.transform.StylesheetSourceDocument
%
%    stylesheet Compiled stylesheet  - matlab.io.xml.transform.CompiledStylesheet
%
%    If input or stylesheet are files stored at a remote location, they
%    must be specified as matlab.io.xml.dom.Document objects created by
%    parsing the files with the matlab.io.xml.dom.Parser.parseFile method.
%    See the matlab.io.xml.dom.Parser.parseFile documentation for details
%    on parsing remote files.
%
%    See also matlab.io.xml.transform.Transformer.transformToString,
%    matlab.io.xml.dom.Parser.parseFile


%    Copyright 2020-2022 MathWorks, Inc.
%    Built-in function.

