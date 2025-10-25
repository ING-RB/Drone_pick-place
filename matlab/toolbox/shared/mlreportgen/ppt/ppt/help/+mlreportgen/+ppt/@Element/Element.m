%mlreportgen.ppt.Element Presentation element
%    Specifies a presentation element.
%
%    Element methods:
%        clone      - Copy element
%
%    Element properties:
%        Style      - Element formatting
%        Children   - Children of this PPT API object
%        Parent     - Parent of this PPT API object
%        Id         - ID for this PPT API object
%        Tag        - Tag for this PPT API object

%    Copyright 2019-2021 The MathWorks, Inc.
%    Built-in class

%{
properties
     %Style Element formatting
     %    Array of PPT format objects that specify the style (appearance)
     %    of this element. Formats that do not apply to this element are
     %    ignored.
     Style;
end
%}