%mlreportgen.dom.ReferencedNote Base class for Footnote and Endnote
%
%    ReferencedNote properties:
%        CustomMark        - Custom mark of this element
%        Style             - Formats that define the mark's style
%        StyleName         - Name of the mark's stylesheet-defined style
%        Children          - Children of this element. DOM objects appended 
%                            to this element  using append method are added here.
%        Parent            - Parent of this element. This element can only be
%                            appended to a Paragraph.
%        Id                - Id of this element
%        Tag               - Tag of this element
%
%    See also mlreportgen.dom.Footnote, mlreportgen.dom.Endnote

%    Copyright 2023 MathWorks, Inc.
%    Built-in class

%{
properties
     %CustomMark Custom mark of this element
     %
     %    Custom mark may be specified as a character vector or a 
     %    string scalar (e.g., 'A') and should not be more than 10
     %    characters long.
     %    If this property is empty, the mark would be a number which would
     %    be auto-generated and auto-incremented for each element    
     %    starting from 1.
     %    
     CustomMark;
end
%}