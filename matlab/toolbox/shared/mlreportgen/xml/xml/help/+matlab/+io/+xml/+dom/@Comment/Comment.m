%matlab.io.xml.dom.Comment Comment in an XML document
%    A Comment object represents a comment in an XML DOM document.
%    
%    Comment methods:
%        appendData              - Append characters
%        cloneNode               - Copy this comment
%        compareDocumentPosition - Get position of this comment
%        deleteData              - Delete characters
%        getBaseURI              - Get base URI
%        getData                 - Get characters
%        getLength               - Get number of characters
%        getNextSibling          - Get node that follows this comment
%        getNodeName             - Get node name of this comment
%        getNodeType             - Get node type of this comment
%        getNodeTypeName         - Get node type name of this comment
%        getNodeValue            - Get node value of this comment
%        getOwnerDocument        - Get document that created this comment
%        getParentNode           - Get parent of this comment
%        getPositionTypeName     - Get name of a position type
%        getPreviousSibling      - Get node previous to this comment
%        getTextContent          - Get content of this comment
%        insertData              - Insert characters
%        isEqualNode             - Whether this comment equals another
%        isSameNode              - Whether a node is this comment
%        replaceData             - Replace characters in this comment
%        setData                 - Set comment to specified characters
%        setNodeValue            - Set node value of this comment node
%        setTextContent          - Set text content of this comment
%        splitText               - Splits comment into two
%        substringData           - Extracts text from this comment
%
%    Comment properties:
%        Length                   - Number of characters in this comment
%        TextContent              - Content of this comment

%    Copyright 2020-2021 MathWorks, Inc.

%{
properties
     %Length Number of characters in comment
     %    The value of this property is a double that specifies the 
     %    number of characters in this comment.
     Length;

     %TextContent Text content of this comment
     %    This property specifies the text content of this comment as a
     %    character vector.
     TextContent;
end
%}