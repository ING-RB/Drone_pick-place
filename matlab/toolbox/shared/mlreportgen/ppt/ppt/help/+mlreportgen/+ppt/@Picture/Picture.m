% mlreportgen.ppt.Picture Picture to include in a presentation
%     pictureObj = Picture() creates an empty picture object.
%
%     pictureObj = Picture(picturePath) creates a picture object containing
%     the picture specified by the picturePath.
%
%    Picture properties:
%        Path       - Picture file path
%        LinkTarget - Picture hyperlink target
%        Name       - Picture name
%        X          - Upper-left x-coordinate position of picture
%        Y          - Upper-left y-coordinate position of picture
%        Width      - Width of picture
%        Height     - Height of picture
%        Style      - Array of picture formats
%        Children   - Children of this PPT API object
%        Parent     - Parent of this PPT API object
%        Id         - ID for this PPT API object
%        Tag        - Tag for this PPT API object
%
%    Picture methods:
%        replace    - Replace picture
%        clone      - Copy picture
%
%    Example 1:
%    % Add a picture to the presentation
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myPicturePresentation.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create a Picture object using an airplane image available in MATLAB.
%    % Specify the size of the picture.
%    plane = Picture(which("b747.jpg"));
%    plane.Width = "5in";
%    plane.Height = "2in";
%
%    % Add the plane picture to the slide
%    replace(slide,"Content",plane);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%
%    Example 2:
%    % Add a figure snapshot to the presentation
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myFigurePresentation.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Add title to the slide
%    replace(slide,"Title","surf(peaks)");
%
%    % Create a MATLAB figure with the surface plot
%    fig = figure;
%    surf(peaks);
%
%    % Print the figure to an image file
%    figSnapshotImage = "figSnapshot.png";
%    print(fig,"-dpng",figSnapshotImage);
%
%    % Create a Picture object using the figure snapshot image file
%    figPicture = Picture(figSnapshotImage);
%
%    % Add the figure snapshot picture to the slide
%    replace(slide,"Content",figPicture);
%
%    % Close the presentation
%    close(ppt);
%
%    % Once the presentation is generated, the figure and the image file
%    % can be deleted
%    delete(fig);
%    delete(figSnapshotImage);
%
%    % View the presentation
%    rptview(ppt);
%
%    See also mlreportgen.ppt.TemplatePicture, print

%    Copyright 2020-2023 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Path Picture file path
     %  Path of the picture file, specified as a character vector or a
     %  string scalar.
     Path;

     %LinkTarget Picture hyperlink target
     %  Internal or external hyperlink target for the picture, specified as
     %  an integer, character vector, or string scalar. Use an integer to
     %  specify the index of the target slide within the presentation. Use
     %  a character vector or string scalar to specify an external URL.
     %  Specify the full URL, for example, include http<strong></strong>://.
     LinkTarget;

end
%}