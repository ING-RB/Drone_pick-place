%mlreportgen.ppt.Italic Italic text
%    italicObj = Italic() creates a format object that specifies italic
%    text.
%
%    italicObj = Italic(value) creates a format object that specifies
%    italic text, if value is true. Otherwise, it specifies non-italic
%    (roman) text.
%
%    Italic properties:
%       Value       - Option to use italic or roman
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code adds a paragraph with italic and roman text to the
%    presentation.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myItalicPresentation.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create a paragraph with italic content
%    p = Paragraph("Italic text");
%    p.Style = {Italic(true)};
%
%    % Add roman text to the paragraph
%    t = Text(" roman text");
%    t.Style = {Italic(false)};
%    append(p,t);
%
%    % Add the paragraph to the slide
%    replace(slide,"Content",p);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Bold, mlreportgen.ppt.Strike,
%    mlreportgen.ppt.Underline

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Option to use italic or roman
     %  Option to use italic or roman for a text object, specified as a
     %  logical value:
     %
     %      true    - renders text in italic
     %      false   - renders roman (straight) text
     Value;

end
%}
