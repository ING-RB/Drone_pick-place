%mlreportgen.ppt.FontColor Font color
%    fontColorObj = FontColor() creates a black font color object.
%
%    fontColorObj = FontColor(color) creates a font color object based on
%    the specified CSS color name or hexadecimal RGB color value.
%
%    fontColorObj = FontColor("rgb(r,g,b)") creates a font color specified by 
%    an rgb triplet such that r,g,b values are in between 0 to 255.
%
%    fontColorObj = FontColor([x y z]) creates a font color specified by an 
%    rgb triplet [x y z] such that each of them is decimal number between 0 and 1.
%
%    FontColor properties:
%       Value       - CSS color name or a hexadecimal RGB value or RGB triplet 
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    The following code adds text of different colors to the presentation.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myFontColor.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create a paragraph
%    p = Paragraph('Hello World');
%
%    % Add red text to the paragraph
%    tRed = Text(' red text');
%    tRed.Style = {FontColor('red')};
%    append(p,tRed);
%
%    % Add blue text to the paragraph
%    tBlue = Text(' blue text');
%    tBlue.Style = {FontColor('#0000ff')};
%    append(p,tBlue);
%
%    % Add the paragraph to the slide
%    replace(slide,"Content",p);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.BackgroundColor

%    Copyright 2019-2022 The MathWorks, Inc.
%    Built-in class
