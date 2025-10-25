%mlreportgen.dom.Paragraph Create a formatted block of text, i.e., a paragraph.
%     paraObj = Paragraph() creates an empty paragraph.
%
%     paraObj = Paragraph(text) creates a paragraph that contains the
%     specified text.
%
%     paraObj = Paragraph(number) creates a paragraph that contains the
%     specified floating-point or integer number.
%
%     paraObj = Paragraph(text, styleName) creates a paragraph that has the
%     specified style. The style specified by the styleName property must
%     be defined in the template used for the document element to which
%     this paragraph is appended.
%
%     paraObj = Paragraph(obj) creates a paragraph that contains the
%     specified object where the object can be any of the following
%     mlreportgen.dom types:
%
%        * ExternalLink
%        * Image
%        * InternalLink
%        * LinkTarget
%        * Number
%        * Text
%
%    Paragraph methods:
%        append         - Append content to this paragraph
%        clone          - Clone this paragraph
%
%    Paragraph properties:
%        BackgroundColor   - Background color of this paragraph
%        Bold              - Whether paragraph text is bold
%        Children          - Children of this paragraph
%        Color             - Color of paragraph text
%        CustomAttributes  - Custom element attributes
%        FirstLineIndent   - Amount to indent paragraph's first line
%        FontFamilyName    - Name of font family used to render paragraph
%        FontSize          - Size of font used to render paragraph
%        HAlign            - Horizontal alignment of this paragraph.  
%        Id                - Id of this paragraph
%        Italic            - Whether this paragraph is italic
%        OuterLeftMargin   - Outer left margin (left indent) of paragraph
%        OutlineLevel      - Outline level of this paragraph
%        Parent            - Parent of this paragraph
%        Style             - Formats that define this paragraph's style
%        Strike            - Type of strikethrough through paragraph
%        StyleName         - Name of paragraph's stylesheet-defined style
%        Tag               - Tag of this paragraph
%        Underline         - Type of line, if any, to draw under paragraph
%        WhiteSpace        - Preserves white space and line breaks

%    Copyright 2013-2022 Mathworks, Inc.
%    Built-in class

%{
properties
     %BackgroundColor Background color of this paragraph
     %    You may specify the background color either as a color
     %    name (e.g., 'red') or a hexadecimal RGB value of the form
     %    '#rrggbb', e.g., 'FF0000' or an RGB triplet (eg. [0 0 1] 
     %    corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color). 
     %    If this property is empty and the paragraph's StyleName property 
     %    specifies a style sheet style, the  color of this paragraph is 
     %    determined by the specified style. 
     %
     %    Note: Setting this property adds a corresponding BackgroundColor 
     %    format object to this paragraph's Style property. Unsetting this 
     %    property removes the object.
     %
     BackgroundColor;

     %Bold Whether this paragraph is bold
     %    If true, this property cause this paragraph to be rendered bold.
     %    If this property is false, the paragraph is rendered normal weight. 
     %    If this property is empty and the paragraph's StyleName property
     %    specifies a stylesheet style, the weight of this paragraph is 
     %    determined by the specified style.
     %
     %    Note: Setting this property adds a corresponding Bold 
     %    format object to this paragraph's Style property. Unsetting this 
     %    property removes the object.
     %
     Bold;

     %Color Color of this paragraph
     %    Color of this paragraph. You may specify the color either as a color
     %    name (e.g., 'red') or a hexadecimal RGB value of the form
     %    '#rrggbb', e.g., 'FF0000' or an RGB triplet (eg. [0 0 1] 
     %    corresponds to blue color) or an RGB triplet string
     %    (eg. 'rgb(0,0,255)' corresponds to blue color). 
     %    If this property is empty and the paragraph's StyleName property 
     %    specifies a style sheet style, the  color of this paragraph is 
     %    determined by the specified style. 
     %
     %    Note: Setting this property adds a corresponding BackgroundColor 
     %    format object to this paragraph's Style property. Unsetting this 
     %    property removes the object.
     %
     Color;

     %FirstLineIndent Amount to indent paragraph's first line.
     %    The amount may be negative. In this case, the first line is not 
     %    indented. Instead, the lines that succeed the first line are 
     %    indented. The value of this property is a string having the 
     %    format valueUnits where Units is an abbreviation for the units 
     %    in which the size is expressed. The following abbreviations are
     %    valid:
     %
     %    Abbreviation  Units
     %
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %
     %   Note: Setting this property adds a corresponding FirstLineIndent 
     %   format object to this paragraph's Style property. Unsetting this
     %   property removes the object.
     FirstLineIndent;

     %FontFamilyName Name of font family to be used to render this paragraph.
     %    If you need to specify substitutions for this font, do not set 
     %    this property. Instead create and add a FontFamily object to 
     %    this paragraph's Style property.
     %
     %    Note: Setting this property adds a corresponding FontFamily 
     %    format object to this paragraph's Style property. Unsetting this 
     %    property removes the object.
     FontFamilyName;

     %FontSize Size of font to be used to render this paragraph.
     %
     %    The value of this property is a string having the format 
     %    valueUnits where Units is an abbreviation for the units in
     %    which the size is expressed. The following abbreviations are
     %    valid:
     %
     %    Abbreviation  Units
     %
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %
     %    Note: Setting this property adds a corresponding FontSize format
     %    object to this paragraph's Style property. Unsetting this property
     %    removes the object.
     FontSize;

     %HAlign Horizontal alignment of this paragraph.  
     %     Valid values are:
     %
     %     Valid Value       Description                        Supported Output Types
     %
     %     'center'          Align center                         All
     %     'distribute'      Distribute all characters equally    Word
     %     'justify'         Justified                            All
     %     'KashidaHigh'     Widest Kashida length                Word
     %     'KashidaLow'      Low Kashida length                   Word
     %     'KashidaMedium'   Medium Kashida length                Word
     %     'left'            Align left                           All
     %     'right'           Align right                          All
     %     'ThaiDistribute'  Thai language justification          Word
     %
     %     Note: Kashida is a type of justification used for some cursive
     %     scripts, primarily Arabic and Persian.
     HAlign;

     %Italic Whether this paragraph is italic
     %    If true, this property cause this paragraph to be rendered italic.
     %    If this property is false, the paragraph is rendered upright. 
     %    If this property is empty and the paragraph's StyleName property
     %    specifies a stylesheet style, the slant of this paragraph is 
     %    determined by the specified style.
     %
     %    Note: Setting this property adds a corresponding Italic 
     %    format object to this paragraph's Style property. Unsetting this 
     %    property removes the object.
     %
     Italic;

     %OuterLeftMargin Outer left margin (left indent) of paragraph
     %    This property specifies the space between the left outer 
     %    boundary of this paragraph and the left inner boundary of its 
     %    container. This is equivalent to the left indentation 
     %    property of a Word pragraph.
     %
     %    The value of this property is a string having the format 
     %    valueUnits where Units is an abbreviation for the units in
     %    which the size is expressed. The following abbreviations are
     %    valid:
     %
     %    Abbreviation  Units
     %
     %    px            pixels
     %    cm            centimeters
     %    in            inches
     %    mm            millimeters
     %    pc            picas
     %    pt            points
     %
     %    Note: Setting this property adds a corresponding OuterMargin 
     %    object to this paragraph's Style property. Unsetting this 
     %    property removes the object. If you want to indent a paragraph
     %    from both the left and right margin of a page, do not set this
     %    property. Instead, add an OuterMargin object specifying the left
     %    and right indents to the paragraph's Style property.
     %
     %    Example
     %
     %    The following lines indent a paragraph a half-inch from the left 
     %    margin of the page of a  Word document.
     %
     %    p = mlreportgen.dom.Paragraph('some text');
     %    p.OuterLeftMargin = '0.5in';
     %
     OuterLeftMargin;

     %OutlineLevel Outline level of this paragraph
     %    Outline level of paragraph, specified as an integer. Setting the
     %    OutlineLevel property causes this paragraph to be included in
     %    automatically generated outlines, such as a table of contents.
     %    The value specifies the level of the paragraph in the outline.
     %    For example, to make a paragraph appear at the top level in an
     %    outline, set the OutlineLevel to 1.
     %
     %    Note: Setting this property adds a corresponding OutlineLevel format 
     %    object to this paragraph's Style property. Unsetting this property
     %    removes the object.
     OutlineLevel;

     %Strike Type of strikethrough, if any, to draw through this paragraph.
     %    Valid types are:
     %
     %    Valid Value      Description
     %
     %    'double'         Double line (Word only)
     %    'none'           Do not draw a strikethrough 
     %    'single'         Single line
     %
     %    Note: Setting this property adds a corresponding Strike format 
     %    object to this paragraph's Style property. Unsetting this property
     %    removes the object.
     Strike;

     %Underline Type of line, if any, to draw under this paragraph
     %    Type of line, if any, to draw under this paragraph. For HTML output, 
     %    the only valid values for this property are 'single' and 'none'.  
     %    In addition to these types, DOCX output supports an extensive 
     %    array of other underline types: 
     %
     %    Valid Value        Description
     %
     %    single             Single underline
     %    words              Underline non-space characters only
     %    double             Double underline
     %    thick              Thick underline
     %    dotted             Dotted underline
     %    dottedHeavy        Thick dotted underline
     %    dash               Dashed underline
     %    dashedHeavy        Thick dashed underline
     %    dashLong           Long dashed underline
     %    dashLongHeavy		 Thick long dashed underline
     %    dotDash		     Dash-dot underline
     %    dashDotHeavy		 Thick dash-dot underline
     %    dotDotDash         Dash-dot-dot underline
     %    dashDotDotHeavy    Thick dash-dot-dot underline
     %    wave               Wavy underline
     %    wavyHeavy          Heavy wavy underline
     %    wavyDouble         Double wavy underline
     %    none               No underline
     %
     %    If this property is empty and the paragraph's StyleName property 
     %    specifies a style sheet style, the line drawn under this paragraph, 
     %    if any, is determined by the specified style. 
     %
     %    If you want to specify the color as well as the type of the
     %    underline, do not set this property, Instead, set this paragraph's
     %    Style property to include an Underline format object that 
     %    specifies the desired type and color.
     %
     %    Note: Setting this property adds a corresponding Underline 
     %    format object to this paragraph's Style property. Unsetting this 
     %    property removes the object.
     Underline;

     %WhiteSpace Preserves white space and line breaks in paragraph.
     %    Handling of white space in text, specified as one of the values
     %    in this table:
     %
     %    Valid Value   Description                             Supported Output Types
     %	
     %    'normal'      For HTML and PDF, removes spaces at     All
     %                  the beginning and the end of text.
     %                  Multiple spaces in the text collapse
     %                  to a single space.
     %                  For Word, removes spaces at the
     %                  beginning and end of text.
     %    'nowrap'      Sequences of white space collapse       HTML
     %                  into a single whitespace. Text never
     %                  wraps to the next line.  		 
     %    'pre'         Preserves white space. Text wraps       HTML and PDF
     %                  only on line breaks. Acts like the
     %                  <pre> tag in HTML.		 
     %    'pre-line'    Sequences of white space                HTML and PDF
     %                  collapse into a single white space.
     %                  Text wraps when necessary and on
     %                  line breaks.		 
     %    'pre-wrap'    Preserves white space. Text wraps       HTML and PDF
     %                  when necessary and on line breaks        		 
     %    'preserve'    Same as 'pre'.                          All
     %
     %     Note: Setting this property adds a corresponding WhiteSpace 
     %     format object to this paragraph's Style property. Unsetting this 
     %     property removes the object.
     WhiteSpace;
end
%}