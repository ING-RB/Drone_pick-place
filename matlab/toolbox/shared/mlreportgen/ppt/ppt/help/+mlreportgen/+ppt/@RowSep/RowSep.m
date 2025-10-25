%mlreportgen.ppt.RowSep Table row separators
%    rowSep = RowSep() creates a format object that specifies that the
%    table to which it applies has thin, solid, black lines serving as
%    separators between the table's rows. You can use the object's
%    properties to specify that the row separators have another style
%    (e.g., dotted), color, and width.
%
%    rowSep = RowSep(style) creates table row separators having the
%    specified style.
%
%    rowSep = RowSep(style,color) creates table row separators having the
%    specified style and color.
%
%    rowSep = RowSep(style,color,width) creates table row separators having
%    the specified style, color, and width.
%
%    RowSep properties:
%       Style           - Style of row separators
%       Color           - Color of row separators
%       Width           - Width of row separators
%       Id              - ID for this PPT API object
%       Tag             - Tag for this PPT API object
%
%    Example:
%    The following code adds a table with custom row separators.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myRowSep.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Table");
%
%    % Create a table and set custom row separators
%    t = Table(magic(3));
%    t.Style = [t.Style {RowSep("dash","red","3pt")}];
%
%    % Add the title and table to the slide
%    replace(slide,"Title","Table with custom row separators");
%    replace(slide,"Table",t);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Table, mlreportgen.ppt.ColSep,
%    mlreportgen.ppt.Border

%    Copyright 2019-2022 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Style Style of row separators
     %  Style of row separators, specified as a character vector or a
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

     %Color Color of row separators
     %  Color of row separators, specified as a character vector or a
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

     %Width Width of row separators
     %  Width of row separators, specified as a character vector or a
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