%mlreportgen.ppt.Underline Underline text
%    underlineObj = Underline() draws a single line under text.
%
%    underlineObj = Underline(style) draws a line of the specified style
%    under the text.
%
%    Underline properties:
%       Style       - Underline style
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code adds a paragraph with underlined text to the
%    presentation.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myUnderlinePresentation.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create a paragraph
%    p = Paragraph("Regular text");
%
%    % Add text with wavy underline
%    tWavy = Text(" wavy underline text");
%    tWavy.Style = {Underline("wavy")};
%    append(p,tWavy);
%
%    % Add text with heavy dash underline
%    tDashed = Text(" heavy dash underline text");
%    tDashed.Style = {Underline("dashheavy")};
%    append(p,tDashed);
%
%    % Add the paragraph to the slide
%    replace(slide,"Content",p);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Bold, mlreportgen.ppt.Italic,
%    mlreportgen.ppt.Strike

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Style Underline style
     %  Underline style, specified as a character vector or a string
     %  scalar. Valid values are:
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
     Style;

end
%}
