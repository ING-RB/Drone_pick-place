%mlreportgen.ppt.Presentation Create a PPT presentation
%
%    ppt = Presentation() creates a presentation named 'Untitled.pptx' in 
%    the current directory.
%
%    ppt = Presentation(presentationPath) creates a presentation at the
%    specified location.
%
%    ppt = Presentation(presentationPath,templatepath) creates a
%    presentation at presentationPath, using the PowerPoint template at
%    templatepath location. If presentationPath and templatepath specify
%    the same presentation, the PPT API will use the presentation as a
%    template for itself, thereby allowing you to update the presentation.
%    The updated presentation replaces the original.
%
%    Presentation methods:
%        open                   - Open presentation
%        close                  - Close presentation
%        find                   - Search presentation
%        replace                - Replace text, tables, or pictures in presentation
%        add                    - Add slide to presentation
%        getMasterNames         - Get names of slide masters for presentation
%        getLayoutNames         - Get names of layouts for presentation slide master
%        getTableStyleNames     - Get table style names for presentation
%        createTemplate         - Create copy of PPT API default presentation template
%
%    Presentation properties:
%        Children           - Content of this presentation
%        Id                 - Id of this presentation
%        OutputPath         - Path of presentation's output directory
%        Tag                - Tag of this presentation
%        TemplatePath       - Path of this presentation's template
%
%    Example:
%
%    % Import the PPT package so that you do not have to use long, fully
%    % qualified names for the PPT API classes
%    import mlreportgen.ppt.*
%
%    % Create an mlreportgen.ppt.Presentation object to contain the slides.
%    % Do not specify a template. Add a slide for the title and a slide for
%    % text.
%    ppt = Presentation("myFirstPresentation.pptx");
%    open(ppt);
%    titleSlide = add(ppt,"Title Slide");
%    textSlide  = add(ppt,"Title and Content");
%
%    % Specify a title for the presentation. Make the title red by creating
%    % the title as an mlreportgen.ppt.Paragraph object and setting the
%    % FontColor format property.
%    paraObj = Paragraph("My First Presentation");
%    paraObj.FontColor = "red";
%    replace(titleSlide,"Title",paraObj);
%
%    % Add content to the second slide
%    replace(textSlide,"Content",{"Subject A","Subject B","Subject C"});
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Slide

%    Copyright 2015-2022 The Mathworks, Inc.

%{
properties

     %OutputPath Path of presentation's output file
     %     You do not specify the file's extension
     %     You cannot set this property once the
     %     presentation has been opened.
     OutputPath;

     %TemplatePath Path of this presentation's template
     %     Path of the PowerPoint template for this presentation. If this
     %     property is empty, a default template is used to generate the
     %     presentation. This property cannot be changed after a
     %     presentation has been opened for output.
     TemplatePath;

end
%}