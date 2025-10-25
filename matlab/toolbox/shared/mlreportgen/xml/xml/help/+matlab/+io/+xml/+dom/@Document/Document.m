%matlab.io.xml.dom.Document Defines an XML document
%    doc = Document() creates an empty XML document.
%
%    doc = Document(docElemName) creates a document with a root element
%    named docElemName.
%
%    Document(docNSURI,docElemQName) creates a document with a root
%    element having the specified namespace URI and qualified name.
%
%    Note: To designate a namespace as the default namespace for a
%    document, omit a prefix from the root element name. For example,
%
%       doc = Document('http://mynamespace.xml','root');
%
%    specifies http://mynamespace.xml as the default namespace for the 
%    root element and its descendants. Descendant element names that lack
%    prefixes reside in the http://mynamespace.xml namespace.
%
%    doc = Document(docElemName,docTypeName,publicId,systemId) creates a
%    document with the specified root element name and document type.
%
%    doc = Document(docElemNSURI,docElemQName,doctypeName,publicId, ...
%          systemId) creates a document having the specified root element
%          and document type where the root element resides in the 
%          specified namespace.
%
%    Document methods:
%       appendChild                  - Add a child to this document
%       cloneNode                    - Create a copy of this document
%       compareDocumentPosition      - Compoare document position
%       createAttribute              - Create attribute
%       createAttributeNS            - Create attribute with qualified name
%       createCDATASection           - Create CDATA section
%       createComment                - Create comment
%       createDocumentFragment       - Create document fragment
%       createElement                - Create element
%       createElementNS              - Create element with qualified name
%       createNSResolver             - Create XPath namespace resolver
%       createProcessingInstruction  - Create a processing instruction
%       createTextNode               - Create a text node
%       getAttributes                - Get attributes
%       getBaseURI                   - Get URI of document's source
%       getChildNodes                - Get document children
%       getChildren                  - Get document's children
%       getDoctype                   - Get document type
%       getDocumentElement           - Get document's root element
%       getDocumentURI               - Get URI of document file
%       getDOMConfig                 - Get document configuration
%       getElementByID               - Get child element by ID
%       getElementsByTagName         - Get child elements by tag name
%       getElementsByTagNameNS       - Get child elements by namespace tag
%       getFirstChild                - Get document's first child
%       getInputEncoding             - Get encoding of document source
%       getLastChild                 - Get document's last child
%       getLocalName                 - Get unqualified document name
%       getNamespaceURI              - Get URI of document name space
%       getNextSibling               - Get next sibling of document
%       getNodeName                  - Get node name of document
%       getNodeType                  - Get node type of document
%       getNodeValue                 - Get document node value
%       getOwnerDocument             - Get owner document
%       getParentNode                - Get document's parent node
%       getPrefix                    - Get prefix of document name
%       getPreviousSibling           - Get previous sibling of document
%       getTextContent               - Get document's text content
%       getXMLEncoding               - Get document's character encoding
%       getXMLStandalone             - Get whether document is standalone
%       getXMLVersion                - Get document's XML version 
%       hasAttributes                - Whether document has attributes
%       hasChildNodes                - Whether document has children
%       importNode                   - Import a node from another document
%       isDefaultNamespace           - Whether namespace is document default
%       isEqualNode                  - Whether document has same content as another
%       isSameNode                   - Whether document is the same as another
%       lookupNamespaceURI           - Find namespace of a prefix
%       lookupPrefix                 - Find prefix associated with namespace
%       normalize                    - Normalize document
%       normalizeDocument            - Normalize document
%       removeChild                  - Remove document child
%       replaceChild                 - Replace document child
%       renameNode                   - Rename document node
%       setDocumentURI               - Set URI of document source file
%       setNodeValue                 - Set document's node value
%       setPrefix                    - Set prefix of document name
%       setTextContent               - Set text content of document
%       setXMLStandalone             - Set document to be standalone
%       xmlwrite                     - Serialize document
%
%    Document properties:
%       Children                     - Children of this document
%       TextContent                  - Text content of document
%       InputEncoding                - Encoding of document source
%       XMLEncoding                  - Declared encoding of document
%       XMLStandalone                - Whether document is declared to be standalone
%       XMLVersion                   - XML version of document
%       DocumentURI                  - Location of document source file
%       Configuration                - Document configuration

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in class

%{
properties
     %InputEncoding Character encoding of document source file
     %    The value of this read-only property is a character array that
     %    specifies the character encoding, e.g., UTF-8, of the file from 
     %    which this document was parsed.
     InputEncoding;

     %XMLEncoding Character encoding specified by XML declaration
     %    The value of this read-only property is a character array
     %    that specifies the character encoding declared in the XML
     %    declaration in the file from which this document was parsed.
     XMLEncoding;

     %XMLStandalone Whether this document is standalone
     %    A value of true declares this document to be a standalone
     %    document. A standalone declaration instructs a parser to 
     %    ignore DTD markup declarations when parsing a file that defines
     %    this document. If this document is parsed from a file whose 
     %    XML declaration declares it to be standalone, the parser sets
     %    this property to true.
     XMLStandalone;
    
     %XMLVersion Version of this document
     %    A character array that specifies the version of this document.
     %    If this document is parsed from a file whose XML declaration
     %    specifies a version, the parser sets this property to the 
     %    specified version.
     XMLVersion;

     %DocumentURI Location of document source file
     %    A character array that specifies the URI of the file that defines
     %    defines this document. If this document is parsed from a file,
     %    the parser sets this property to a URI specifying the location
     %    of the file.
     DocumentURI;

     %Configuration Document configuration
     %    The value of this property is a
     %    matlab.io.xml.dom.DocumentConfiguration object that specifies
     %    options for normalizing this document.
     %
     %    See also matlab.io.xml.dom.DocumentConfiguration,
     %    matlab.io.xml.dom.Document.normalizeDocument
     Configuration;
end
%}