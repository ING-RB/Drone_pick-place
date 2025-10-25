%replace Replace text, tables, or pictures in a slide
%     replace(slide,contentName,content) replaces the existing content in a
%     slide content object with the specified content, which can be one or
%     more paragraphs, a table, or a picture. If the type of content that
%     you specify in the content argument is not valid for the content
%     object identified by contentName, the replace method has no effect.
%
%    Example:
%
%     % Create a presentation
%     import mlreportgen.ppt.*
%     ppt = Presentation("mySlideReplacePresentation.pptx");
%     open(ppt);
%
%     % Add a slide for text, a slide for a picture, and a slide for a
%     % table
%     slide1 = add(ppt,"Title and Content");
%     slide2 = add(ppt,"Title and Picture");
%     slide3 = add(ppt,"Title and Table");
%
%     % In the first slide, replace the "Title" and "Content" placeholders
%     % with text
%     replace(slide1,"Title","Text Slide");
%     replace(slide1,"Content","This is the content for slide 1");
%
%     % In the second slide, replace the "Title" placeholder with text and
%     % the "Picture" placeholder with a picture
%     replace(slide2,"Title","Picture Slide");
%     replace(slide2,"Picture",Picture(which("b747.jpg")));
%
%     % In the third slide, replace the "Title" placeholder with text and
%     % the "Table" placeholder with a table
%     replace(slide3,"Title","Table Slide");
%     replace(slide3,"Table",Table({1, 2; "a", "b"}));
%
%     % Close and view the presentation
%     close(ppt);
%     rptview(ppt);
%
%    See also mlreportgen.ppt.Slide

%    Copyright 2020 The MathWorks, Inc.
%    Built-in function.
