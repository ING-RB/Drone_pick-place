%matlab.io.xml.dom.Locator Deterimine element location in an XML file
%   An instance of this class specifies the location of an element in 
%   an XML file.  
%
%    Locator properties:
%       PublicID     - Public ID of file containing element
%       SystemID     - System ID of file containing element
%       LineNumber   - Line number of element
%       ColumnNumber - Column number of element
%
%    See also matlab.io.xml.dom.ResourceIdentifier

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %PublicID PublicID of file containing the XML element
     PublicID;

     %SystemID System ID (location) of file containing the XML element
     SystemID;

     %LineNumber Line number of XML element
     LineNumber;

     %ColumnNumber Column number of XML element
     ColumnNumber;

end
%}