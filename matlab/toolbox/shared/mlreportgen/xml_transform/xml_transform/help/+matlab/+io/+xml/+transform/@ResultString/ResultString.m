%matlab.io.xml.transform.ResultString String resulting from a transform
%    result = ResultString() creates a container in which to store a string
%    containing the result of a transformation.
%
%    ResultString properties:
%       String - String contained by this result object
%
%   See also matlab.io.xml.transform.Transformer.transform

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in class

%{
properties
     %String String contained by this result object
     %    A string scalar containing the result of a document
     %    transformation stored in this object.
     String;
end
%}