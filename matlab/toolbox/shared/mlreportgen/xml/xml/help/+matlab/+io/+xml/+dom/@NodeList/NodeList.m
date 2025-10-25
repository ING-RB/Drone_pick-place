%matlab.io.xml.dom.NodeList List of document nodes
%    A NodeList object contains a list of document nodes.
%    
%    NodeList methods:
%        getLength      - Get number of items in list
%        getTextContent - Get concatenated text content of list items
%        item           - Get list item at zero-based index
%        node           - Get list item at one-based index
%
%    NodeList properties:
%        Length       - Number of items in the list
%        TextContent  - Concatenated text content of list items
%
%    See also matlab.io.xml.dom.Node.getChildNodes

%    Copyright 2020 MathWorks, Inc.

%{
properties
     %Length Number of items in node list
     Length;

     %TextContent Concatenated text content of list items
     TextContent;
end
%}