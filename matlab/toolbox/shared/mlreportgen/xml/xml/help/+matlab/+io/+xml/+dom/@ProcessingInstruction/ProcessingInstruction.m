%matlab.io.xml.dom.ProcessingInstruction Defines a processing instruction.
%   A processing instruction provides data to an application intended to
%   facilitate processing of the XML document in which the processing
%   instruction is embedded. For example, a processing instruction might
%   specify the location of the stylesheet used to transform the XML 
%   document.
%
%   Note: a processing instruction inherits methods and properties from
%   Node class that do not apply to processing instructions and hence are
%   ineffective or throw errors. Use only documented processing instruction
%   methods and properties with processing instructions.
%
%   ProcessingInstruction methods:
%       getData    - Get the processing instruction data
%       getTarget  - Get the processing instruction target
%       setData    - Set the processing instruction data
%
%    ProcessingInstruction properties:
%       Data   - Processing instruction data
%       Target - Processing instruction target

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %Data Processing instruction data
     Data;

     %Target Processing instruction target
     Target;

end
%}