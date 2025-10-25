%transform Transform an XML document
%    transform(transformer,input,stylesheet,output) transforms the
%    specified input document using the specified stylesheet and stores the
%    result in the location specified by output argument. See the table
%    below for the argument data types accepted by this method.
%
%    transform(transformer,input,output) transforms the specified input
%    document and stores the result in the location specified by the output
%    argument. This method requires that the input document contain a
%    processing instruction that specifies the stylesheet to be used to
%    transform the document. For example, the following lines begin an XML
%    document that specifies use of a stylesheet named "catalog.xml"
%    located in the current working directory.
%     
%     <?xml version="1.0" encoding="UTF-8"?>
%     <?xml-stylesheet type="text/xsl" href="catalog.xsl"?>
%
%     See the table below for the argument data types accepted by this
%     method.
%
%    document = transform(transformer,input,stylesheet) transforms the
%    specified input document, using the specified stylesheet, and returns
%    the result as a document of type matlab.io.xml.dom.Document. See the
%    table below for the input argument data types accepted by this method.
%
%    document = transform(transformer,input) transforms the specified input
%    document and returns the result as a document of type
%    matlab.io.xml.dom.Document. This method requires that the input
%    document contain a processing instruction that specifies the
%    stylesheet to be used to transform the document. See the table below
%    for the input argument data types accepted by this method.
%
%    The following table summarizes the data types that can be used to 
%    specify transform argument values:
%
%    Argument    Value               Data Type
%    ======================================================================
%    transformer transformer         matlab.io.xml.transform.Transformer
%   
%    input       XML file path       - string scalar
%                                    - character vector
%                                    - matlab.io.xml.transform.SourceFile
%
%    input       XML string          - matlab.io.xml.transform.SourceString
%
%    input       Parsed XML document - matlab.io.xml.dom.Document
%                                    - matlab.io.xml.transform.SourceDocument
%    
%    output      XML file path       - string scalar
%                                    - character vector
%                                    - matlab.io.xml.transform.ResultFile
%    
%    output      XML string          matlab.io.xml.transform.ResultString
%
%    output      Parsed XML document matlab.io.xml.transform.ResultDocument
%
%    stylesheet  XML file path       - string scalar
%                                    - character vector
%                                    - matlab.io.xml.transform.StylesheetSourceFile
%
%    stylesheet  XML string          - matlab.io.xml.transform.StylesheetSourceString
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
%    matlab.io.xml.transform.Transformer.compileStylesheet,
%    matlab.io.xml.dom.Parser.parseFile

%    Copyright 2020-2022 MathWorks, Inc.
%    Built-in function.

