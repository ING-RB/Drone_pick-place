%mlreportgen.ppt.Superscript Superscript text
%    superscriptObj = Superscript() creates a format object that specifies
%    superscript text.
%
%    superscriptObj = Superscript(value) creates a format object that
%    specifies superscript text, if value is true. Otherwise, it specifies
%    regular text.
%
%    Superscript properties:
%       Value       - Option to display text as superscript
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code adds a paragraph with superscript text to the
%    presentation.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("mySuperscript.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create a paragraph
%    p = Paragraph("x");
%
%    % Append superscript text to the paragraph
%    super = Text("2");
%    super.Style = {Superscript(true)};
%    append(p,super);
%
%    % Add the paragraph to the slide
%    replace(slide,"Content",p);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Subscript

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Option to display text as superscript
     %  Option to display text as superscript, specified as a logical
     %  value:
     %
     %      true    - renders text as superscript
     %      false   - renders as regular text
     Value;

end
%}
