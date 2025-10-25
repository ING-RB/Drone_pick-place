%mlreportgen.ppt.HAlign Horizontal alignment of paragraph
%    hAlignObj = HAlign() creates a horizontal alignment object that
%    specifies left alignment.
%
%    hAlignObj = HAlign(value) creates a horizontal alignment object based
%    on the specified alignment value.
%
%    HAlign properties:
%       Value       - Horizontal alignment
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code adds a horizontally centered title to the title
%    slide of the presentation.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myHAlignPresentation.pptx");
%    open(ppt);
%
%    % Add a title slide to the presentation
%    titleSlide = add(ppt,"Title Slide");
%
%    % Create a centered paragraph
%    p = Paragraph("Title for First Slide");
%    p.Style = {HAlign("center")};
%
%    % Add the paragraph to the title slide
%    replace(titleSlide,"Title",p);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.VAlign

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Horizontal alignment
     %  Horizontal alignment, specified as a character vector or a string
     %  scalar. Valid values are:
     %
     %      TYPE                DESCRIPTION
     %      'left'              Left-justified (default)
     %      'right'             Right-justified
     %      'center'            Centered
     %      'justified'         Left- and right-justified, spacing words evenly
     %      'distributed'       Left- and right-justified, spacing letters evenly
     %      'thaiDistributed'   Left- and right-justified Thai text, spacing characters evenly
     %      'justifiedLow'      Justification for Arabic text
     Value;

end
%}