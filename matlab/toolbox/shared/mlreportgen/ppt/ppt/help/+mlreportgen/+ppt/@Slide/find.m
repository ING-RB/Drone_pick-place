%find Search slide for content
%     searchResults = find(slide,objectName) searches a slide for a slide
%     content object whose Name property value matches objectName.
%
%    Example:
%
%     % Create a presentation
%     import mlreportgen.ppt.*
%     ppt = Presentation("mySlideFindPresentation.pptx");
%     open(ppt);
%
%     % Add a slide with "Title and Content" layout
%     slide = add(ppt,"Title and Content");
%
%     % Search the slide for a content object that has the Name property
%     % value as "Content"
%     contents = find(slide,"Content");
%
%     % The find returns a 1-by-1 array that contains an
%     % mlreportgen.ppt.ContentPlaceholder object. Specify that text in the
%     % placeholder object is bold and add text to the object.
%     contents(1).Bold = true;
%     add(contents(1),"This is bold text");
%
%     % Close and view the presentation
%     close(ppt);
%     rptview(ppt);
%
%    See also mlreportgen.ppt.Slide

%    Copyright 2020 The MathWorks, Inc.
%    Built-in function.
