%mlreportgen.ppt.Bold Bold text
%    boldObj = Bold() creates a format object that specifies bold text.
%
%    boldObj = Bold(value) creates a format object that specifies bold
%    text, if value is true. Otherwise, it specifies regular weight text.
%
%    Bold properties:
%       Value       - Option to use bold or regular weight
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code adds a paragraph with bold and regular-weight text
%    to the presentation.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myBoldPresentation.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create a paragraph with bold content
%    p = Paragraph("Bold text");
%    p.Style = {Bold(true)};
%
%    % Add regular-weight text to the paragraph
%    t = Text(" regular weight text");
%    t.Style = {Bold(false)};
%    append(p,t);
%
%    % Add the paragraph to the slide
%    replace(slide,"Content",p);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Italic, mlreportgen.ppt.Strike,
%    mlreportgen.ppt.Underline

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Option to use bold or regular weight
     %  Option to use bold or regular weight for a text object, specified
     %  as a logical value:
     %
     %      true    - renders text in bold
     %      false   - renders regular weight text
     Value;

end
%}
