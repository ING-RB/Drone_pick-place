%mlreportgen.ppt.Node Presentation node
%    Specifies a presentation node.
%
%    Node properties:
%        Children   - Children of this PPT API object
%        Parent     - Parent of this PPT API object
%        Id         - ID for this PPT API object
%        Tag        - Tag for this PPT API object

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties
     %Children Children of this PPT API object
     %    This read-only property lists child elements that the object
     %    contains, specified as a cell array.
     Children;

     %Parent Parent of this PPT API object
     %    This read-only property lists the parent of this object,
     %    specified as a PPT object.
     Parent;
end
%}