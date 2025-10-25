%matlab.io.xml.dom.CDATASection Text to be output unescaped
%    A CDATA section is a type of text object whose content is serialized
%    as is, without escaping XML markup characters.
%
%    Note: The XML parser converts the markup <![CDATA[...]]> to a
%    CDATASection object where ... is a string of characters. You can use
%    unescaped characters in the CDATA section markup. For example, you can
%    use > instead of &gt; to indicate a > character in the CDATA section.
%    CDATA section markup facilitates inclusion of computer code and
%    mathematical expressions in XML documents by eliminating the need to
%    use character entities to indicate >, <, and other characters that
%    occur in both XML markup and code and math expressions.
%    
%    CDATASection methods:
%        appendData                  - Append characters
%        cloneNode                   - Copy this CDATA section
%        compareDocumentPosition     - Get relative position of this section
%        deleteData                  - Delete characters
%        getBaseURI                  - Get base URI
%        getData                     - Get characters
%        getLength                   - Get number of characters
%        getNextSibling              - Get node that follows this section
%        getNodeName                 - Get node name of this section
%        getNodeType                 - Get node type of this section
%        getNodeTypeName             - Get type name of this section
%        getNodeValue                - Get node value of this section
%        getOwnerDocument            - Get document that created this section
%        getParentNode               - Get parent of this section
%        getPreviousSibling          - Get node previous to this section
%        getTextContent              - Get content of this section
%        insertData                  - Insert characters
%        isEqualNode                 - Whether this section equals another
%        isSameNode                  - Whether a node is this node
%        replaceData                 - Replace characters in this section
%        setData                     - Set section to specified data
%        setNodeValue                - Set node value of this section
%        setTextContent              - Set text content of this section
%        splitText                   - Splits section into two
%        substringData               - Extracts text from this section
%
%    CDATASection properties:
%        Length                   - Number of characters in this section
%        TextContent              - Content of this section
%
%    Example
%
%    import matlab.io.xml.dom.*
%    d = Document('book');
%    e = getDocumentElement(d);
%    tn = createTextNode(d,'x > 1 | x < 2');
%    appendChild(e,tn);
%    cdata = createCDATASection(d,'x > 1 | x < 2');
%    appendChild(e,cdata);
%    str = writeToString(DOMWriter,d); % str =
%    % '<?xml version="1.0" encoding="UTF-16" standalone="no" ?><book>
%    % <![CDATA[x > 1 | x < 2]]>x &gt; 1 | x &lt; 2</book>'

%    Copyright 2021 MathWorks, Inc.

%{
properties
     %Length Number of characters in the CDATA section
     %    The value of this property is a double that specifies the 
     %    number of characters in this section's text content.
     Length;

     %TextContent Text content of this CDATA section
     %    This property specifies the text content of this section as a
     %    character vector.
     TextContent;
end
%}