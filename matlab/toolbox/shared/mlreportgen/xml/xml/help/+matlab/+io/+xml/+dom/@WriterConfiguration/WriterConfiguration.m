%matlab.io.xml.dom.WriterConfiguration Defines XML DOM writer options
%
%    WriterConfiguration properties:
%        FormatPrettyPrint       - Format output for readability
%        FormatPrettyPrintDouble - Pretty print using two line feeds
%        XMLDeclaration          - Output XML declaration
%        DTD                     - Output document type definition
%        BOM                     - Output byte order mark
%        DiscardDefaultContent   - Do not output default content
%        SplitCDATASections      - Split CDATA sections
%
%    See also matlab.io.xml.dom.DOMWriter

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in class

%{
properties
    %FormatPrettyPrint Whether to pretty-print the output XML markup
    %    If this option is true, format the output by adding white space 
    %    to produce a pretty-printed, indented, human-readable form.
    %    If this option is false (default), do not pretty-print the 
    %    result.
    FormatPrettyPrint;

    %FormatPrettyPrintDouble Whether to pretty print with two line feeds
    %    If this option is true, insert two line feed characters between
    %    XML elements in pretty printed output. If this option is false 
    %    (default), insert a single line feed between elements.
    FormatPrettyPrintDouble;

    %XMLDeclaration Whether to output an XML declaration
    %    If this option is true (default), include an XML declaration in 
    %    the output. If this option is false, do not include an XML
    %    declaration.
    XMLDeclaration;

    %DTD Whether to output a Document Type Definition (DTD)
    %    If this option is true (default) and the DOM document contains a 
    %    Document Type Declaration (DTD), include the DTD in XML file
    %    output. If this option is false, do not include the DTD.
    DTD;

    %BOM Whether to output a byte order mark (BOM)
    %    If this option is true, write a byte order mark (BOM) at the
    %    beginning of the XML file output stream. If this option is false
    %   (default), do not write a BOM.
    %
    %    Note: The BOM is written only if a file is being written and 
    %    the output encoding is among the encodings listed here 
    %    (aliases acceptable): UTF-8, UTF-16, UTF-16LE, UTF-16BE, UCS-4, 
    %    UCS-4LE, and UCS-4BE. In the case of UTF-16/UCS-4, the host
    %    machine's endian mode is used to determine the appropriate BOM to
    %    be written.  
    BOM;

    %DiscardDefaultContent Whether to output default content
    %    If this option is true (default), use whatever information is 
    %    available (i.e. XML schema, DTD, the specified flag on Attr nodes, 
    %    and so on) to decide what attributes and content should be 
    %    discarded. If this option is false, keep all attributes and all 
    %    content. 
    DiscardDefaultContent;

    %SplitCDATASections Whether to split CDATA sections
    %    If this option is true (default), split CDATA sections containing
    %    the CDATA section termination marker ']]>', or unrepresentable 
    %    characters in the output encoding. If this option is false, throw
    %    an error if a CDATASection contains a CDATA section termination
    %    marker ']]>' or an unrepresentable character.
    SplitCDATASections;
end
%}