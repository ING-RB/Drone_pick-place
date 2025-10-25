%mlreportgen.dom.LOF Creates a list of figures
%    lof = LOF() creates a list of figures
%    with a dots ('.') leader pattern.
%
%
%    lof = LOF(pattern) creates a list of figures 
%    with the specified leader pattern.
%
%    LOF methods:
%        clone              - Clone this LOF object
%
%    LOF properties:
%        LeaderPattern      - Leader pattern
%        StyleName          - Name of LOF object's style sheet-defined style
%        Style              - Formats that define this LOF object's style
%        CustomAttributes   - Custom element attributes
%        Children           - Children of this LOF object
%        Parent             - Parent of this LOF object
%        Tag                - Tag of this LOF object
%        Id                 - Id for this LOF object

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties

     %LeaderPattern Leader pattern
     %    This property specifies the type of leader to use between figure 
     %    caption and page number in list of figures.
     %
     %    Valid values are:
     %
     %    Value               DESCRIPTION
     %    'dots' or '.'       leader of dots
     %    'space' or ' '      leader of spaces
     LeaderPattern;

end
%}