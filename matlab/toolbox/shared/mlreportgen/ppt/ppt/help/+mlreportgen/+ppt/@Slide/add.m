%add Add text box, table, or picture to slide
%     addedObj = add(slide,object) adds the specified
%     mlreportgen.ppt.TextBox, mlreportgen.ppt.Table, or
%     mlreportgen.ppt.Picture object to a slide.
%
%    Example:
%
%     % Create a presentation
%     import mlreportgen.ppt.*
%     ppt = Presentation("mySlideAddPresentation.pptx");
%     open(ppt);
%
%     % Add a slide with "Blank" layout
%     slide = add(ppt,"Blank");
%
%     % Create an mlreportgen.ppt.Picture object for the picture that you
%     % want to add to the slide. Use the Picture object properties to
%     % specify the size of the picture in the slide.
%     plane = Picture(which("b747.jpg"));
%     plane.X = "4in";
%     plane.Y = "4in";
%     plane.Width = "5in";
%     plane.Height = "2in";
%
%     % Add the Picture object to the slide
%     add(slide,plane);
%
%     % Close and view the presentation
%     close(ppt);
%     rptview(ppt);
%
%    See also mlreportgen.ppt.TextBox, mlreportgen.ppt.Table,
%    mlreportgen.ppt.Picture, mlreportgen.ppt.Slide

%    Copyright 2020 The MathWorks, Inc.
%    Built-in function.
