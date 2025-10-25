%parseString Parse an XML string
%    doc = parseString(thisParser,xmlStr) parses the specified XML markup
%    and returns the result as a Document object. The xmlStr argument may
%    be a string scalar or a character vector. This method throws an error
%    if it encounters a markup error in the string being parsed. To continue
%    parsing in the face of errors, configure the parser to use a custom
%    error handler. In this case, the parser may return an invalid
%    document.
%
%    Note: The XML markup to be parsed must declare only one top-level
%    element, which may be preceded or followed by a comment or processing
%    instruction. If the markup declares more than one top-level element,
%    the parser throws an error after processing the first element. The
%    parser gives "comment or processing instruction expected" as the
%    reason for the error.
%
%    See also matlab.io.xml.dom.Document,
%    matlab.io.xml.dom.Parser.parseFile,
%    matlab.io.xml.dom.Parser.Configuration,
%    matlab.io.xml.dom.ParseErrorHandler

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in function.