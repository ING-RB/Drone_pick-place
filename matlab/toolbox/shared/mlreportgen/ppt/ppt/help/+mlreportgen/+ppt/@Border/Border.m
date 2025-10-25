%mlreportgen.ppt.Border Border of a table or table entry
%    border = Border() creates a format object that specifies that the
%    table or table entry to which it applies has thin, solid, black lines
%    serving as the borders. You can use the object's properties to specify
%    that the borders have another style (e.g., dotted), color, and width.
%
%    border = Border(style) creates a border having the specified style.
%
%    border = Border(style,color) creates a border having the specified
%    style and color.
%
%    border = Border(style,color,width) creates a border having the
%    specified style, color, and width.
%
%    Note: A conflict occurs if a border segment is shared by two table
%    entries. For a conflicting horizontal border segment, PowerPoint
%    ignores the styles specified by the entry on the bottom. For a
%    conflicting vertical border segment, PowerPoint ignores the styles
%    specified by the entry on the right.
%
%    Border properties:
%       Style           - Default style of border segments
%       Color           - Default color of border segments
%       Width           - Default width of border segments
%       TopStyle        - Style of top border segment
%       TopColor        - Color of top border segment
%       TopWidth        - Width of top border segment
%       BottomStyle     - Style of bottom border segment
%       BottomColor     - Color of bottom border segment
%       BottomWidth     - Width of bottom border segment
%       LeftStyle       - Style of left border segment
%       LeftColor       - Color of left border segment
%       LeftWidth       - Width of left border segment
%       RightStyle      - Style of right border segment
%       RightColor      - Color of right border segment
%       RightWidth      - Width of right border segment
%       Id              - ID for this PPT API object
%       Tag             - Tag for this PPT API object
%
%    Example:
%    The following code sets the custom border for the second entry in the
%    second row of the table.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myTEBorders.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Table");
%
%    % Create a table
%    t = Table(magic(3));
%
%    % Create a border object to customize the bottom segment
%    border = Border();
%    border.BottomStyle = "dash";
%    border.BottomColor = "red";
%    border.BottomWidth = "3pt";
%
%    % Apply custom border to the second column entry in the second row
%    tr2te2 = t.entry(2,2);
%    tr2te2.Style = [tr2te2.Style {border}];
%
%    % Add the title and table to the slide
%    replace(slide,"Title","Table entry with custom borders");
%    replace(slide,"Table",t);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.TableEntry, mlreportgen.ppt.Table,
%    mlreportgen.ppt.RowSep, mlreportgen.ppt.ColSep

%    Copyright 2019-2022 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Style Default style of border segments
     %  Default style of border segments, specified as a character vector
     %  or a string scalar. Valid values are:
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

     %Color Default color of border segments
     %  Default color of border segments, specified as a character vector
     %  or a string scalar. Use either a CSS color name or a hexadecimal
     %  RGB value or an RGB triplet (eg. [0 0 1] corresponds to blue color) or 
     %  an RGB  triplet string (eg. 'rgb(0,0,255)' corresponds to blue color).
     %
     %  For a list of CSS color names, see
     %  https://www.w3.org/wiki/CSS/Properties/color/keywords.
     %
     %  To specify a hexadecimal RGB format, use # as the first character
     %  and two-digit hexadecimal numbers for each for the red, green, and
     %  blue values. For example, '#0000ff' specifies blue.
     Color;

     %Width Default width of border segments
     %  Default width of border segments, specified as a character vector
     %  or a string scalar. Use the format valueUnits, where Units is an
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

     %TopStyle Style of top border segment
     %  Top border segment style, specified as a character vector or a
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
     TopStyle;

     %TopColor Color of top border segment
     %  Top border segment color, specified as a character vector or a
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
     TopColor;

     %TopWidth Width of top border segment
     %  Top border segment width, specified as a character vector or a
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
     TopWidth;

     %BottomStyle Style of bottom border segment
     %  Bottom border segment style, specified as a character vector or a
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
     BottomStyle;

     %BottomColor Color of bottom border segment
     %  Bottom border segment color, specified as a character vector or a
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
     BottomColor;

     %BottomWidth Width of bottom border segment
     %  Bottom border segment width, specified as a character vector or a
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
     BottomWidth;

     %LeftStyle Style of left border segment
     %  Left border segment style, specified as a character vector or a
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
     LeftStyle;

     %LeftColor Color of left border segment
     %  Left border segment color, specified as a character vector or a
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
     LeftColor;

     %LeftWidth Width of left border segment
     %  Left border segment width, specified as a character vector or a
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
     LeftWidth;

     %RightStyle Style of right border segment
     %  Right border segment style, specified as a character vector or a
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
     RightStyle;

     %RightColor Color of right border segment
     %  Right border segment color, specified as a character vector or a
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
     RightColor;

     %RightWidth Width of right border segment
     %  Right border segment width, specified as a character vector or a
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
     RightWidth;

end
%}