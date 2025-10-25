%replace Replace picture
%     pictureObj = replace(picture,replacementPicture) replaces a picture
%     with another picture.
%
%     Example:
%
%     % Create a presentation
%     import mlreportgen.ppt.*
%     ppt = Presentation("myPictureReplacePresentation.pptx");
%     open(ppt);
%
%     % Add a slide to the presentation
%     slide = add(ppt,"Blank");
%
%     % Create a Picture object
%     plane = Picture(which("b747.jpg"));
%     plane.X = "1in";
%     plane.Y = "1in";
%     plane.Width = "5in";
%     plane.Height = "2in";
%
%     % Add the picture to the slide
%     add(slide,plane);
%
%     % Create a second picture
%     peppers = Picture(which("peppers.png"));
%     peppers.X = "1in";
%     peppers.Y = "1in";
%     peppers.Width = "3in";
%     peppers.Height = "3in";
%
%     % Replace the plane picture with the peppers picture
%     replace(plane,peppers);
%
%     % Close and view the presentation
%     close(ppt);
%     rptview(ppt);
%
%    See also mlreportgen.ppt.Picture

%    Copyright 2020 The MathWorks, Inc.
%    Built-in function.
