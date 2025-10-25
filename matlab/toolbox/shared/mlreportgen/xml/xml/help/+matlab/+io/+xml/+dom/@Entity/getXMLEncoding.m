%getXMLEncoding Get a file entity's XML encoding 
%    encoding = getXMLEncoding(thisEntity) returns the encoding of the file
%    specified by this entity as a character vector. This method returns 
%    an encoding only if the entity specifies an XML file, the specified
%    file has been parsed, and the encoding could be determined by parsing. 
%    Otherwise this method returns an empty character vector.
%
%    See also matlab.io.xml.dom.Entity.getInputEncoding

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.