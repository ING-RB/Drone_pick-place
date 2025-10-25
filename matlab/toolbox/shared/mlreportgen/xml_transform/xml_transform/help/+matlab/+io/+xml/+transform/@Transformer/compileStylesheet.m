%compileStylesheet Compile a stylesheet
%    compiledStylesheet = compileStylesheet(transformer,source)
%    compiles the specified stylesheet source and returns the result
%    as an object of matlab.io.xml.transform.CompiledStylesheet. The
%    method accepts the following argument types;
%
%    Argument     Value        Data Type
%    ======================================================================
%    transformer  transformer  - matlab.io.xml.transform.Transformer
%    
%    source       stylesheet   - string scalar
%                 file path    - character vector
%                              - matlab.io.xml.transform.StylesheetSourceFile
%
%    source       stylesheet   - matlab.io.xml.dom.Document
%                 document     - matlab.io.xml.transform.StylesheetSourceDocument
%
%    source       stylesheet   - matlab.io.xml.transform.StylesheetSourceString
%                 string       

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in function.
