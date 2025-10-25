%mlreportgen.ppt.ColSpec Formatting for table column
%    colSpecObj = ColSpec() creates an empty table column specification
%    object.
%
%    colSpecObj = ColSpec(colWidth) creates a column specification object
%    having the specified column width.
%
%    ColSpec properties:
%       Width               - Column width
%       Bold                - Option to use bold for column text
%       Font                - Font family for column text
%       ComplexScriptFont   - Font family for complex scripts
%       FontColor           - Font color for column text
%       FontSize            - Font size for column text
%       Italic              - Option to use italic for column text
%       Strike              - Column text strikethrough style
%       Subscript           - Option to display column text as a subscript
%       Superscript         - Option to display column text as a superscript
%       Underline           - Column text underline style
%       BackgroundColor     - Column background color
%       HAlign              - Horizontal alignment of column content
%       VAlign              - Vertical alignment of column content
%       TextOrientation     - Orientation of column text
%       Style               - Array of PPT API formats
%       Children            - Children of this PPT API object
%       Parent              - Parent of this PPT API object
%       Id                  - ID for this PPT API object
%       Tag                 - Tag for this PPT API object
%
%    Example:
%    The following code sets the width and background color for the first
%    two columns of a table.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myColSpec.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Table");
%
%    % Create a table
%    table = Table(magic(12));
%    table.Style = {HAlign("center")};
%
%    % Define formatting for the first table column using ColSpec
%    colSpecs(1) = ColSpec("1in");
%    colSpecs(1).BackgroundColor = "red";
%
%    % Define formatting for the second table column using ColSpec
%    colSpecs(2) = ColSpec("2in");
%    colSpecs(2).BackgroundColor = "green";
%
%    % Set the ColSpecs property of the Table object to the colSpecs
%    table.ColSpecs = colSpecs;
%
%    % Add the table to the slide
%    replace(slide,"Table",table);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Table

%    Copyright 2019-2021 The MathWorks, Inc.
%    Built-in class

%{
properties
     %Width Column width
     %  Table column width, specified as a character vector or a string
     %  scalar. Use the format valueUnits, where Units is an abbreviation
     %  for the column width. These abbreviations are valid:
     %
     %      ABBREVIATION    UNITS
     %      px              pixels (default)
     %      cm              centimeters
     %      in              inches
     %      mm              millimeters
     %      pc              picas
     %      pt              points
     %
     %  See also mlreportgen.ppt.ColWidth
     Width;

     %Bold Option to use bold for column text
     %  Option to use bold for the column text, specified as a logical
     %  value:
     %
     %      true    - renders text in bold
     %      false   - renders regular weight text
     %
     %  See also mlreportgen.ppt.Bold
     Bold;

     %Font Font family for column text
     %  Font family for the column text, specified as a character vector or
     %  a string scalar. Specify a font that appears in the PowerPoint list
     %  of fonts in the Home tab Font area.
     %
     %  See also mlreportgen.ppt.FontFamily
     Font;

     %ComplexScriptFont Font family for complex scripts
     %  Font family for complex scripts, specified as a character vector or
     %  a string scalar. Specify a font family for substituting in a locale
     %  that requires a complex script (such as Arabic or Asian) for
     %  rendering text.
     %
     %  See also mlreportgen.ppt.FontFamily
     ComplexScriptFont;

     %FontColor Font color for column text
     %  Font color for the column text, specified as a character vector or
     %  a string scalar. Use either a CSS color name or a hexadecimal RGB
     %  value.
     %
     %  For a list of CSS color names, see
     %  https://www.w3.org/wiki/CSS/Properties/color/keywords.
     %
     %  To specify a hexadecimal RGB format, use # as the first character
     %  and two-digit hexadecimal numbers for each for the red, green, and
     %  blue values. For example, '#0000ff' specifies blue.
     %
     %  See also mlreportgen.ppt.FontColor
     FontColor;

     %FontSize Font size for column text
     %  Font size for the column text, specified as a character vector or a
     %  string scalar. Use the format valueUnits, where Units is an
     %  abbreviation for the font size unit. These abbreviations are valid:
     %
     %      ABBREVIATION    UNITS
     %      px              pixels (default)
     %      cm              centimeters
     %      in              inches
     %      mm              millimeters
     %      pc              picas
     %      pt              points
     %
     %  See also mlreportgen.ppt.FontSize
     FontSize;

     %Italic Option to use italic for column text
     %  Option to use italic for the column text, specified as a logical
     %  value:
     %
     %      true    - renders text in italic
     %      false   - renders roman (straight) text
     %
     %  See also mlreportgen.ppt.Italic
     Italic;

     %Strike Column text strikethrough style
     %  Column text strikethrough style, specified as a character vector or
     %  string scalar. Valid values are:
     %
     %      TYPE        DESCRIPTION
     %      'single'    Single horizontal line (default)
     %      'double'    Double horizontal line
     %      'none'      No strikethrough line
     %
     %  See also mlreportgen.ppt.Strike
     Strike;

     %Subscript Option to display column text as a subscript
     %  Option to display column text as a subscript, specified as a
     %  logical value:
     %
     %      true    - renders text as a subscript
     %      false   - renders as regular text
     %
     %  See also mlreportgen.ppt.Subscript
     Subscript;

     %Superscript Option to display column text as a superscript
     %  Option to display column text as a superscript, specified as a
     %  logical value:
     %
     %      true    - renders text as a superscript
     %      false   - renders as regular text
     %
     %  See also mlreportgen.ppt.Superscript
     Superscript;

     %Underline Column text underline style
     %  Column text underline style, specified as a character vector or a
     %  string scalar. Valid values are:
     %
     %      TYPE                DESCRIPTION
     %      'single'            Single underline (default)
     %      'double'            Double underline
     %      'heavy'             Thick underline
     %      'words'             Words only underlined (not spaces)
     %      'dotted'            Dotted underline
     %      'dottedheavy'       Thick, dotted underline
     %      'dash'              Dashed underline
     %      'dashheavy'         Thick, dashed underline
     %      'dashlong'          Long, dashed underline
     %      'dashlongheavy'     Thick, long, dashed underline
     %      'dotdash'           Dot dash underline
     %      'dotdashheavy'      Thick, dot dash underline
     %      'dotdotdash'        Dot dot dash underline
     %      'dotdotdashheavy'   Thick, dot dot dash underline
     %      'wavy'              Wavy underline
     %      'wavyheavy'         Thick, wavy underline
     %      'wavydouble'        Wavy, double underline
     %      'none'              No underline
     %
     %  See also mlreportgen.ppt.Underline
     Underline;

     %BackgroundColor Column background color
     %  Column background color, specified as a character vector or a
     %  string scalar. Use either a CSS color name or a hexadecimal RGB
     %  value.
     %
     %  For a list of CSS color names, see
     %  https://www.w3.org/wiki/CSS/Properties/color/keywords.
     %
     %  To specify a hexadecimal RGB format, use # as the first character
     %  and two-digit hexadecimal numbers for each for the red, green, and
     %  blue values. For example, '#0000ff' specifies blue.
     %
     %  See also mlreportgen.ppt.BackgroundColor
     BackgroundColor;

     %HAlign Horizontal alignment of column content
     %  Horizontal alignment of the column content, specified as a
     %  character vector or a string scalar. Valid values are:
     %
     %      TYPE                DESCRIPTION
     %      'left'              Left-justified (default)
     %      'right'             Right-justified
     %      'center'            Centered
     %      'justified'         Left- and right-justified, spacing words evenly
     %      'distributed'       Left- and right-justified, spacing letters evenly
     %      'thaiDistributed'   Left- and right-justified Thai text, spacing characters evenly
     %      'justifiedLow'      Justification for Arabic text
     %
     %  See also mlreportgen.ppt.HAlign
     HAlign;

     %VAlign Vertical alignment of column content
     %  Vertical alignment of the column content, specified as a character
     %  vector or a string scalar. Valid values are:
     %
     %      TYPE                DESCRIPTION
     %      'top'               Content aligned vertically to the top (default)
     %      'bottom'            Content aligned vertically to the bottom
     %      'middle'            Content aligned vertically to the middle
     %      'topCentered'       Content aligned vertically to the top and horizontally to the center
     %      'bottomCentered'    Content aligned vertically to the bottom and horizontally to the center
     %      'middleCentered'    Content aligned vertically to the middle and horizontally to the center
     %
     %  See also mlreportgen.ppt.VAlign
     VAlign;

     %TextOrientation Orientation of column text
     %  Orientation of the column text, specified as a character vector or
     %  a string scalar. Valid values are:
     %
     %    horizontal  - text orientation is horizontal
     %    down        - text orientation is vertical, with the content
     %                  rotated 90 degrees clockwise
     %    up          - text orientation is vertical, with the content
     %                  rotated 90 degrees counterclockwise
     %
     %    Example:
     %    The following code sets table column text orientation to be
     %    vertical.
     %
     %    % Create a presentation
     %    import mlreportgen.ppt.*
     %    ppt = Presentation("myTextOrientation.pptx");
     %    open(ppt);
     %
     %    % Add a slide to the presentation
     %    slide = add(ppt,"Title and Table");
     %
     %    % Create a table
     %    table = Table({'Col 1', 'Col 2'; 'entry 1', 'entry 2'});
     %    table.Height = "2in";
     %    table.Style = [table.Style {VAlign("middleCentered")}];
     %
     %    % Define formatting for the first table column using ColSpec
     %    colSpecs(1) = ColSpec("1in");
     %    colSpecs(1).TextOrientation = "up";
     %
     %    % Define formatting for the second table column using ColSpec
     %    colSpecs(2) = ColSpec("1in");
     %    colSpecs(2).TextOrientation = "down";
     %
     %    % Set the ColSpecs property of the Table object to the colSpecs
     %    table.ColSpecs = colSpecs;
     %
     %    % Add the table to the slide
     %    replace(slide,"Table",table);
     %
     %    % Close and view the presentation
     %    close(ppt);
     %    rptview(ppt);
     %
     %  See also mlreportgen.ppt.TextOrientation
     TextOrientation;

end
%}