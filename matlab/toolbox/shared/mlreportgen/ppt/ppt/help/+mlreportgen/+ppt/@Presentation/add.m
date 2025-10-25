%add Add slide to presentation
%     slideObj = add(presentation,layoutName) creates and adds a slide
%     to the presentation, based on the layout, layoutName, defined in
%     the presentation's template. If the template specifies more than
%     one layout having the specified name, the PPT API uses the first
%     layout of that name that it finds in the template.
%
%     slideObj = add(presentation,layoutName,masterName) creates
%     and adds a slide to the presentation, based on the layout,
%     layoutName, specified by the layout master, masterName, defined
%     by the presentation. Use this method to select a layout from
%     multiple layouts having the same name.
%
%     slideObj = add(presentation,layoutName,otherSlide) creates a
%     slide based on the layout, layoutName, and inserts the new slide
%     before otherSlide.
%
%     slideObj = add(presentation,layoutName,masterName,otherSlide)
%     creates a slide based on the specified layout inserts the new slide
%     before otherSlide.
%
%     slideObj = add(presentation,layoutName,index) creates a
%     slide based on the specified layout and inserts the new slide
%     at the specified position. For example, if index = 1, the
%     new slide becomes the first slide in the presentation and the
%     slide that was previously first becomes the second slide in
%     the presentations.
%
%     slideObj = add(presentation,layoutName,masterName,index) creates a
%     slide based on the specified layout and inserts the new slide at
%     the specified position.
%
%     Example:
%
%     % Import the PPT package so that you do not have to use long, fully
%     % qualified names for the PPT API classes
%     import mlreportgen.ppt.*
%
%     % Create and open a presentation named "myPresentation.pptx"
%     ppt = Presentation("myPresentation.pptx");
%     open(ppt);
%
%     % Add the first slide and specify the slide layout, but not the slide
%     % master or location
%     contentSlide = add(ppt,"Title and Content");
%     replace(contentSlide,"Title","This is the Title of the Slide Content");
%
%     % Add another slide using the "Office Theme" slide master. Insert it
%     % before the slide represented by contentSlide.
%     titleSlide = add(ppt,"Title Slide","Office Theme",contentSlide);
%     replace(titleSlide,"Title","Presentation Title");
%
%     % Add a blank slide using the "Office Theme" slide master. Make the
%     % new slide the second slide in the presentation.
%     blankSlide = add(ppt,"Blank","Office Theme",2);
%
%     % Close and view the presentation
%     close(ppt);
%     rptview(ppt);
%
%    See also mlreportgen.ppt.Slide

%    Copyright 2015-2022 The MathWorks, Inc.
%    Built-in function.

