%mlreportgen.ppt.Slide Presentation slide
%    An object of the mlreportgen.ppt.Slide class represents a slide in a
%    Microsoft PowerPoint presentation. To create a Slide object and add it
%    to a presentation, use the add method of an
%    mlreportgen.ppt.Presentation object. The add method returns the Slide
%    object. You can use the Slide object methods to add, find, and replace
%    slide content.
%
%    Slide properties:
%        Layout         - Slide layout name
%        SlideMaster    - Slide master name
%        Name           - Slide name
%        Style          - Slide formatting
%        Children       - Children of this slide object
%        Parent         - Parent of this slide object
%        Tag            - Tag for this slide object
%        Id             - ID for this slide object
%
%    Slide methods:
%        add            - Add text box, table, or picture to slide
%        find           - Search slide for content
%        replace        - Replace text, tables, or pictures in a slide
%
%    Example:
%
%     % Create a presentation
%     import mlreportgen.ppt.*
%     ppt = Presentation("mySlidePresentation.pptx");
%     open(ppt);
%
%     % Add a slide with "Title and Table" layout
%     slide = add(ppt,"Title and Table");
%
%     % Replace the "Title" placeholder in the slide with the title text
%     replace(slide,"Title","magic(4)");
%
%     % Replace the "Table" placeholder in the slide with a table
%     replace(slide,"Table",Table(magic(4)));
%
%     % Close and view the presentation
%     close(ppt);
%     rptview(ppt);
%
%    See also mlreportgen.ppt.Presentation

%    Copyright 2020 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Layout Slide layout name
     %     Slide layout name, specified as a character vector. This
     %     property is read-only.
     Layout;

     %SlideMaster Slide master name
     %     Slide master name, specified as a character vector. This
     %     property is read-only.
     SlideMaster;

     %Name Slide name
     %     Slide name, specified as a character vector or string scalar.
     %     You can set the Name property to identify a slide in a
     %     presentation.
     %
     %     See also mlreportgen.ppt.Presentation.find
     Name;

end
%}