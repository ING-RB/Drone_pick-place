%mlreportgen.ppt.ColSep Table column separators
%    colSep = ColSep() creates a format object that specifies that the
%    table to which it applies has thin, solid, black lines serving as
%    separators between the table's columns. You can use the object's
%    properties to specify that the column separators have another style
%    (e.g., dotted), color, and width.
%
%    colSep = ColSep(style) creates table column separators having the
%    specified style.
%
%    colSep = ColSep(style,color) creates table column separators having
%    the specified style and color.
%
%    colSep = ColSep(style,color,width) creates table column separators
%    having the specified style, color, and width.
%
%    ColSep properties:
%       Style           - Style of column separators
%       Color           - Color of column separators
%       Width           - Width of column separators
%       Id              - ID for this PPT API object
%       Tag             - Tag for this PPT API object
%
%    Example:
%    The following code adds a table with custom column separators.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myColSep.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Table");
%
%    % Create a table and set custom column separators
%    t = Table(magic(3));
%    t.Style = [t.Style {ColSep("dash","red","3pt")}];
%
%    % Add the title and table to the slide
%    replace(slide,"Title","Table with custom column separators");
%    replace(slide,"Table",t);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Table, mlreportgen.ppt.RowSep,
%    mlreportgen.ppt.Border

%    Copyright 2019-2022 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Style Style of column separators
     %  Style of column separators, specified as a character vector or a
     %  string scalar. Valid values are:
     %
     %      'none'
     %      'solid'
     %      'dot'
     %      'dash'
     %      'largeDash'
     %      'dashDot'
     %      'largeDashDot'
     %      'largeDashDotDot'
     %      'systemDash'
     %      'systemDot'
     %      'systemDashDot'
     %      'systemDashDotDot'
     Style;

     %Color Color of column separators
     %  Color of column separators, specified as a character vector or a
     %  string scalar. Use either a CSS color name or a hexadecimal RGB
     %  value or an RGB triplet (eg. [0 0 1] corresponds to blue color) or 
     %  an RGB  triplet string (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %  For a list of CSS color names, see
     %  https://www.w3.org/wiki/CSS/Properties/color/keywords.
     %
     %  To specify a hexadecimal RGB format, use # as the first character
     %  and two-digit hexadecimal numbers for each for the red, green, and
     %  blue values. For example, '#0000ff' specifies blue.
     Color;

     %Width Width of column separators
     %  Width of column separators, specified as a character vector or a
     %  string scalar. Use the format valueUnits, where Units is an
     %  abbreviation for the units. These abbreviations are valid:
     %
     %    Abbreviation  Units
     %    px            pixels (default)
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     Width;

end
%}