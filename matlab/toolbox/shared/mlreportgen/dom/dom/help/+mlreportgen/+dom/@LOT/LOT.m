%mlreportgen.dom.LOT Creates a list of tables
%    lot = LOT() creates a list of tables
%    with a dots ('.') leader pattern.
%
%
%    lot = LOT(pattern) creates a list of tables 
%    with the specified leader pattern.
%
%    LOT methods:
%        clone              - Clone this LOT object
%
%    LOT properties:
%        LeaderPattern      - Leader pattern
%        StyleName          - Name of LOT object's style sheet-defined style
%        Style              - Formats that define this LOT object's style
%        CustomAttributes   - Custom element attributes
%        Children           - Children of this LOT object
%        Parent             - Parent of this LOT object
%        Tag                - Tag of this LOT object
%        Id                 - Id for this LOT object

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties

     %LeaderPattern Leader pattern
     %    This property specifies the type of leader to use between table   
     %    caption and page number in list of tables.
     %
     %    Valid values are:
     %
     %    Value               DESCRIPTION
     %    'dots' or '.'       leader of dots
     %    'space' or ' '      leader of spaces
     LeaderPattern;

end
%}