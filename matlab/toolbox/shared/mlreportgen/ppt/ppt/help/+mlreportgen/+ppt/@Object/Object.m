%mlreportgen.ppt.Object Presentation object
%    Specifies a presentation object.
%
%    Object properties:
%        Id         - ID for this PPT API object
%        Tag        - Tag for this PPT API object

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties
     %Id ID for this PPT API object
     %    ID for PPT API object, specified as a string or character vector.
     %    A session-unique ID is generated as part of object creation. You
     %    can specify an ID to replace the generated ID.
     Id;

     %Tag Tag for this PPT API object
     %    Tag for this PPT API object, specified as a string or character
     %    vector. The generated tag has the form CLASS:ID, where CLASS is
     %    the object class and ID is the value of the Id property of the
     %    object.
     %
     %    An example of a reason for specifying your own tag value is to
     %    make it easier to identify where an issue occurred during
     %    presentation generation.
     Tag;
end
%}