%mlreportgen.ppt.BaseTextBox Base class for PPT API text box classes
%    Specifies the base class for the PPT API text box classes.
%
%    BaseTextBox properties:
%        Bold                 - Option to use bold for text
%        Font                 - Font family for text
%        ComplexScriptFont    - Font family for complex scripts
%        FontColor            - Font color for text
%        FontSize             - Font size for text
%        Italic               - Option to use italic for text
%        Strike               - Text strikethrough style
%        Subscript            - Option to display text as a subscript
%        Superscript          - Option to display text as a superscript
%        Underline            - Text underline style
%        BackgroundColor      - Text box background color
%        VAlign               - Vertical alignment of text
%        Name                 - Shape name
%        X                    - Upper-left x-coordinate position
%        Y                    - Upper-left y-coordinate position
%        Width                - Width of the shape
%        Height               - Height of the shape
%        Style                - Shape formatting
%        Children             - Children of this PPT API object
%        Parent               - Parent of this PPT API object
%        Tag                  - Tag for this PPT API object
%        Id                   - ID for this PPT API object
%
%    See also mlreportgen.ppt.TextBox, mlreportgen.ppt.TextBoxPlaceholder

%    Copyright 2020-2022 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Bold Option to use bold for text
     %  Option to use bold for the text, specified as a logical value:
     %
     %      true    - renders text in bold
     %      false   - renders regular weight text
     %
     %  See also mlreportgen.ppt.Bold
     Bold;

     %Font Font family for text
     %  Font family for the text, specified as a character vector or a
     %  string scalar. Specify a font that appears in the font list in
     %  Microsoft PowerPoint. To see the font list, in PowerPoint, on the
     %  Home tab, in the Font group, click the arrow to the right of the
     %  font.
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

     %FontColor Font color for text
     %  Font color for text, specified as a character vector or a string
     %  scalar. Use either a CSS color name or a hexadecimal RGB value or 
     %  an RGB triplet (eg. [0 0 1] corresponds to blue color) or an RGB 
     %  triplet string (eg. 'rgb(0,0,255)' corresponds to blue color).
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

     %FontSize Font size for text
     %  Font size of text, specified as a character vector or a string
     %  scalar. Use the format valueUnits, where Units is an abbreviation
     %  for the font size. These abbreviations are valid:
     %
     %  Abbreviation  Units
     %
     %  px            pixels (default)
     %  cm            centimeters
     %  in            inches
     %  mm            millimeters
     %  pc            picas
     %  pt            points
     %
     %  See also mlreportgen.ppt.FontSize
     FontSize;

     %Italic Option to use italic for text
     %  Option to use italic for the text, specified as a logical value:
     %
     %      true    - renders text in italic
     %      false   - renders roman (straight) text
     %
     %  See also mlreportgen.ppt.Italic
     Italic;

     %Strike Text strikethrough style
     %  Text strikethrough style, specified as a character vector or a
     %  string scalar. Valid values are:
     %
     %      TYPE        DESCRIPTION
     %      'single'    Single horizontal line
     %      'double'    Double horizontal line
     %      'none'      No strikethrough line
     %
     %  See also mlreportgen.ppt.Strike
     Strike;

     %Subscript Option to display text as a subscript
     %  Option to display text as a subscript, specified as a logical
     %  value:
     %
     %      true    - renders text as a subscript
     %      false   - renders as regular text
     %
     %  See also mlreportgen.ppt.Subscript
     Subscript;

     %Superscript Option to display text as a superscript
     %  Option to display text as a superscript, specified as a logical
     %  value:
     %
     %      true    - renders text as a superscript
     %      false   - renders as regular text
     %
     %  See also mlreportgen.ppt.Superscript
     Superscript;

     %Underline Text underline style
     %  Text underline style, specified as a character vector or a string
     %  scalar. Valid values are:
     %
     %      TYPE                DESCRIPTION
     %      'single'            Single underline
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

     %BackgroundColor Text box background color
     %  Text box background color, specified as a character vector or a
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
     %
     %  See also mlreportgen.ppt.BackgroundColor
     BackgroundColor;

     %VAlign Vertical alignment of text
     %  Vertical alignment of text, specified as a character vector or a
     %  string scalar. Valid values are:
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

end
%}