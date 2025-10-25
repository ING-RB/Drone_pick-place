%mlreportgen.dom.Preformatted Create a paragraph that preserves white-space text formatting
%
% Create a paragraph that preserves white-space text formatting, i.e.,
% formatting that uses spaces, line feeds, and a monospaced font to break
% text into a block of text containing indented and unindented lines. This
% object simplifies adding program code, which typically uses white-space
% formatting, to a report.
%
% If this object does not specify a FontFamilyName or WhiteSpace property,
% the DOM API uses default values for these properties when outputting the
% object's text content. The default values, which depend on the report
% type (HTML, Word, or PDF), preserve the text's white space formatting.
% You can override the default values by setting this object's WhiteSpace
% and FontFamilyName properties.
%
%     preObj = Preformatted() creates an empty preformatted paragraph.
%
%     preObj = Preformatted(text) creates a preformatted paragraph that
%     contains the specified text.
%
%     preObj = Preformatted(text, styleName) creates a preformatted
%     paragraph that has the specified style. The style specified by the
%     styleName property must be defined in the template used for the
%     document element to which this paragraph is appended.
%
%     preObj = Preformatted(obj) creates a preformatted paragraph
%     that contains the specified object where the object can be any of the
%     following mlreportgen.dom types:
%
%        * ExternalLink
%        * Image
%        * InternalLink
%        * LinkTarget
%        * Text
%
%    Preformatted methods:
%        append         - Append content to this paragraph
%        clone          - Clone this paragraph
%
%    Preformatted properties:
%        BackgroundColor   - Background color of this preformatted paragraph
%        Bold              - Whether preformatted paragraph text is bold
%        Children          - Children of this preformatted paragraph
%        Color             - Color of preformatted paragraph text
%        CustomAttributes  - Custom element attributes
%        FirstLineIndent   - Amount to indent preformatted paragraph's first line
%        FontFamilyName    - Name of font family used to render preformatted paragraph
%        FontSize          - Size of font used to render preformatted paragraph
%        HAlign            - Horizontal alignment of this preformatted paragraph.  
%        Id                - Id of this preformatted paragraph
%        Italic            - Whether this preformatted paragraph is italic
%        OuterLeftMargin   - Outer left margin (left indent) of preformatted paragraph
%        OutlineLevel      - Outline levelof this preformatted paragraph
%        Parent            - Parent of this preformatted paragraph
%        Style             - Formats that define this preformatted paragraph's style
%        Strike            - Type of strikethrough through preformatted paragraph
%        StyleName         - Name of preformatted paragraph's stylesheet-defined style
%        Tag               - Tag of this preformatted paragraph
%        Underline         - Type of line, if any, to draw under preformatted paragraph
%        WhiteSpace        - Preserves white space and line breaks

%    Copyright 2019 Mathworks, Inc.
%    Built-in class