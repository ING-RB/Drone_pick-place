%matlab.io.xml.dom.DocumentConfiguration Defines document normalization
%
%    DocumentConfiguration properties:
%        CDATASections - Whether to keep CDATASections
%        Comments      - Whether to keep comments
%        Namespaces    - Whether to normalize namespaces
%
%    See also matlab.io.xml.dom.Document.Configuration,
%    matlab.io.xml.dom.Document.normalizeDocument

%    Copyright 2021 MathWorks, Inc.
%    Built-in class

%{
properties
    %CDATASections Whether to convet CDATASections to text
    %    If this option is true (default), the document's
    %    normalizeDocument method keeps CDATASection nodes in the 
    %    document. Otherwise, it converts the sections to text nodes and
    %    merges them with adjacent text nodes.
    CDATASections;

    %Comments Whether to retain comments
    %    If this option is true (default), the document's 
    %    normalizeDocument method keeps comments in the document. 
    %    Otherwise, it deletes the comments.
    Comments;

    %Namespaces Whether to normalize namespaces
    %    If this option is true (default), the document's
    %    normalizeDocument method normalizes the document's namespaces.
    %    Otherwise, it does not normalize namespaces.
    %
    %    See also https://www.w3.org/TR/DOM-Level-3-Core/namespaces-algorithms.html
    Namespaces;

end
%}