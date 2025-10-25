%mlreportgen.ppt.Strike Strike through text
%    strikeObj = Strike() draws a single, horizontal line through text.
%
%    strikeObj = Strike(style) draws a line of the specified style through
%    text.
%
%    Strike properties:
%       Style       - Strike style
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code adds a paragraph with strike through text to the
%    presentation.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myStrikePresentation.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create a paragraph
%    p = Paragraph();
%
%    % Add text with strikethrough formatting
%    t = Text("strikethrough text");
%    t.Style = {Strike("double")};
%    append(p,t);
%
%    % Add text without strikethrough formatting
%    t = Text(" visible text");
%    append(p,t);
%
%    % Add the paragraph to the slide
%    replace(slide,"Content",p);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Bold, mlreportgen.ppt.Italic,
%    mlreportgen.ppt.Underline

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Style Strike style
     %  Strike style, specified as a character vector or a string scalar.
     %  Valid values are:
     %
     %      TYPE        DESCRIPTION
     %      'single'    Single horizontal line (default)
     %      'double'    Double horizontal line
     %      'none'      No strikethrough line
     Style;

end
%}
