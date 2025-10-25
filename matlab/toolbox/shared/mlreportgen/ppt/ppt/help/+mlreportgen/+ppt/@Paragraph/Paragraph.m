% mlreportgen.ppt.Paragraph Formatted block of text (paragraph)
%     paraObj = Paragraph() creates an empty paragraph object.
%
%     paraObj = Paragraph(text) creates a paragraph that contains a
%     mlreportgen.ppt.Text object with the specified text content.
%
%     paraObj = Paragraph(pptElementObj) creates a paragraph that contains
%     the specified pptElementObj, which can be of type:
%         - mlreportgen.ppt.Text
%         - mlreportgen.ppt.Number
%         - mlreportgen.ppt.ExternalLink
%         - mlreportgen.ppt.InternalLink
%
%    Paragraph methods:
%        append             - Append content to this paragraph
%        clone              - Copy paragraph
%
%    Paragraph properties:
%      Bold                 - Option to use bold for text
%      Font                 - Font family for text
%      ComplexScriptFont    - Font family for complex scripts
%      FontColor            - Font color for text
%      FontSize             - Font size for text
%      Italic               - Option to use italic for text
%      Strike               - Text strikethrough style
%      Subscript            - Option to display text as a subscript
%      Superscript          - Option to display text as a superscript
%      Underline            - Text underline style
%      HAlign               - Horizontal alignment of text
%      Level                - Indentation level of paragraph
%      Style                - Array of PPT API formats
%      Children             - Children of this PPT API object
%      Parent               - Parent of this PPT API object
%      Id                   - ID for this PPT API object
%      Tag                  - Tag for this PPT API object
%
%    Example:
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myParagraphPresentation.pptx");
%    open(ppt);
%
%    % Add two slides to the presentation
%    slide1 = add(ppt,"Title Slide");
%    slide2 = add(ppt,"Title and Content");
%
%    % Create a Paragraph object to use for the title of the presentation.
%    % Make the text bold and red.
%    p1 = Paragraph("My Presentation Title");
%    p1.Bold = true;
%    p1.FontColor = "red";
%
%    % Replace the title for the first slide with the p1 paragraph
%    replace(slide1,"Title",p1);
%
%    % Create a paragraph for the content of the second slide
%    p2 = Paragraph("My content");
%    append(p2,Text(" for the second slide"));
%
%    % Replace the content for the second slide with the p2 paragraph
%    replace(slide2,"Content",p2);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Text, mlreportgen.ppt.TextBox,
%    mlreportgen.ppt.Number, mlreportgen.ppt.ExternalLink,
%    mlreportgen.ppt.InternalLink

%    Copyright 2020-2024 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Bold Option to use bold for text
     %  Option to use bold for the text in this paragraph, specified as a
     %  logical value:
     %
     %      true    - renders text in bold
     %      false   - renders regular weight text
     %
     %  See also mlreportgen.ppt.Bold
     Bold;

     %Font Font family for text
     %  Font family for the text in this paragraph, specified as a
     %  character vector or a string scalar. Specify a font that appears in
     %  the font list in Microsoft PowerPoint. To see the font list, in
     %  PowerPoint, on the Home tab, in the Font group, click the arrow to
     %  the right of the font.
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
     %  Font color for text in this paragraph, specified as a character
     %  vector or a string scalar. Use either a CSS color name or a
     %  hexadecimal RGB value or an RGB triplet (eg. [0 0 1] corresponds to blue color) or 
     %  an RGB  triplet string (eg. 'rgb(0,0,255)' corresponds to blue color).
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
     %  Font size of text in this paragraph, specified as a character
     %  vector or a string scalar. Use the format valueUnits, where Units
     %  is an abbreviation for the font size. These abbreviations are
     %  valid:
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
     %  Option to use italic for the text in this paragraph, specified as a
     %  logical value:
     %
     %      true    - renders text in italic
     %      false   - renders roman (straight) text
     %
     %  See also mlreportgen.ppt.Italic
     Italic;

     %Strike Text strikethrough style
     %  Strikethrough style for the text in this paragraph, specified as a
     %  character vector or a string scalar. Valid values are:
     %
     %      TYPE        DESCRIPTION
     %      'single'    Single horizontal line
     %      'double'    Double horizontal line
     %      'none'      No strikethrough line
     %
     %  See also mlreportgen.ppt.Strike
     Strike;

     %Subscript Option to display text as a subscript
     %  Option to display text in this paragraph as a subscript, specified
     %  as a logical value:
     %
     %      true    - renders text as a subscript
     %      false   - renders as regular text
     %
     %  See also mlreportgen.ppt.Subscript
     Subscript;

     %Superscript Option to display text as a superscript
     %  Option to display text in this paragraph as a superscript,
     %  specified as a logical value:
     %
     %      true    - renders text as a superscript
     %      false   - renders as regular text
     %
     %  See also mlreportgen.ppt.Superscript
     Superscript;

     %Underline Text underline style
     %  Underline style for the text in this paragraph, specified as a
     %  character vector or a string scalar. Valid values are:
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

     %HAlign Horizontal alignment of text
     %  Horizontal alignment of the text in this paragraph, specified as a
     %  character vector or a string scalar. Valid values are:
     %
     %      TYPE                DESCRIPTION
     %      'left'              Left-justified
     %      'right'             Right-justified
     %      'center'            Centered
     %      'justified'         Left-justified and right-justified, spacing words evenly
     %      'distributed'       Left-justified and right-justified, spacing letters evenly
     %      'thaiDistributed'   Left-justified and right-justified Thai text, spacing characters evenly
     %      'justifiedLow'      Justification for Arabic text
     %
     %  See also mlreportgen.ppt.HAlign
     HAlign;

     %Level Indentation level of paragraph
     %  Indentation level of this paragraph, specified as an integer in the
     %  range [1,9]. The value 1 indicates a top-level paragraph (no
     %  indentation).
     Level;

end
%}
