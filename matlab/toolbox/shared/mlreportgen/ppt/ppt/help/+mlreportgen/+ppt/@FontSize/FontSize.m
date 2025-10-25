%mlreportgen.ppt.FontSize Font size
%    fontSizeObj = FontSize() creates a 12pt font size object.
%
%    fontSizeObj = FontSize(value) creates a font size object based on the
%    specified font size value.
%
%    FontSize properties:
%       Value       - Font size value
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code adds a paragraph with different font size text
%    objects to the presentation.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myFontSizePresentation.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create a paragraph
%    p = Paragraph();
%
%    % Append large font size text to the paragraph
%    tWarning = Text("WARNING:");
%    tWarning.Style = {FontSize("40pt"), Bold(true), FontColor("red")};
%    append(p,tWarning);
%
%    % Append default font size text to the paragraph
%    tDesc = Text(" Unplug the machine before doing the next steps.");
%    append(p,tDesc);
%
%    % Add the paragraph to the slide
%    replace(slide,"Content",p);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.FontColor, mlreportgen.ppt.FontFamily

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class
