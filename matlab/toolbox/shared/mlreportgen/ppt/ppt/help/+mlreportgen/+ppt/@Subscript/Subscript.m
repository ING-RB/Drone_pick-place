%mlreportgen.ppt.Subscript Subscript text
%    subscriptObj = Subscript() creates a format object that specifies
%    subscript text.
%
%    subscriptObj = Subscript(value) creates a format object that specifies
%    subscript text, if value is true. Otherwise, it specifies regular
%    text.
%
%    Subscript properties:
%       Value       - Option to display text as subscript
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code adds a paragraph with subscript text to the
%    presentation.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("mySubscript.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create a paragraph
%    p = Paragraph("H");
%
%    % Append subscript text to the paragraph
%    sub = Text("2");
%    sub.Style = {Subscript(true)};
%    append(p,sub);
%
%    % Append regular text to the paragraph
%    append(p,"O");
%
%    % Add the paragraph to the slide
%    replace(slide,"Content",p);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Superscript

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Option to display text as subscript
     %  Option to display text as subscript, specified as a logical value:
     %
     %      true    - renders text as subscript
     %      false   - renders as regular text
     Value;

end
%}
