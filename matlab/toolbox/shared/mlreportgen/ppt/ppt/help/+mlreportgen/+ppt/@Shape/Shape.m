%mlreportgen.ppt.Shape Shape in the presentation
%    Specifies a shape in the presentation.
%
%    Shape properties:
%        Name       - Shape name
%        X          - Upper-left x-coordinate position
%        Y          - Upper-left y-coordinate position
%        Width      - Width of the shape
%        Height     - Height of the shape
%        Style      - Shape formatting
%        Children   - Children of this PPT API object
%        Parent     - Parent of this PPT API object
%        Id         - ID for this PPT API object
%        Tag        - Tag for this PPT API object

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties
     %Name Shape name
     %     Specifies the shape name.
     Name;

    %X Upper-left x-coordinate position
     %    Specifies the upper-left x-coordinate position of the shape in
     %    the form of valueUnits where Units is an abbreviation for the
     %    units. Valid abbreviations are:
     %
     %    Abbreviation  Units
     %    px            pixels (default)
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %    Note: The value parsed from the template presentation is
     %    specified in English Metric Units (EMUs).
     X;

    %Y Upper-left y-coordinate position
     %    Specifies the upper-left y-coordinate position of the shape in
     %    the form of valueUnits where Units is an abbreviation for the
     %    units. Valid abbreviations are:
     %
     %    Abbreviation  Units
     %    px            pixels (default)
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %    Note: The value parsed from the template presentation is
     %    specified in English Metric Units (EMUs).
     Y;

    %Width Width of the shape
     %    Specifies the width of the shape in the form of valueUnits where
     %    Units is an abbreviation for the units. Valid abbreviations are:
     %
     %    Abbreviation  Units
     %    px            pixels (default)
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %    Note: The value parsed from the template presentation is
     %    specified in English Metric Units (EMUs).
     Width;

    %Height Height of the shape
     %    Specifies the height of the shape in the form of valueUnits where
     %    Units is an abbreviation for the units. Valid abbreviations are:
     %
     %    Abbreviation  Units
     %    px            pixels (default)
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %    Note: The value parsed from the template presentation is
     %    specified in English Metric Units (EMUs).
     Height;
end
%}