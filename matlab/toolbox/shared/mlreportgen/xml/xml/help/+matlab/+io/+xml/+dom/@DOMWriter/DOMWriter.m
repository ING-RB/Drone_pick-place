%matlab.io.xml.dom.DOMWriter Defines a writer that serializes an XML document
%   writer = DOMWriter() creates a writer to serialize a
%   matlab.io.xml.dom.Document object.
%
%   DOMWriter methods:
%       write         - Mix serialized XML and non-XML output
%       writeToFile   - Serialize DOM document to a file
%       writeToString - Serialize DOM document to a string
%       setNewLine    - Set new line character
%       getNewLine    - Get new line character
%
%    DOMWriter properties:
%       Configuration - Write options
%
%    See also matlab.io.dom.xml.Document,
%    matlab.io.dom.xml.WriterConfiguration, 
%    matlab.io.dom.xml.FileWriter

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %Configuration DOMWriter configuration
     %    The value of this read-only property is an object that specifies
     %    DOMWriter options. Although the property is read-only, you can 
     %    change the writer options that it specifies.
     %    
     %    See also matlab.io.xml.dom.WriterConfiguration
     Configuration;
end
%}