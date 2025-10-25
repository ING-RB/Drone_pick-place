classdef FormalImage< mlreportgen.report.Reporter
%mlreportgen.report.FormalImage Create a captioned image reporter
%    image = FormalImage() creates an empty image reporter. You can use
%    the reporter's properties to specify an image source, caption,
%    height, width, etc. The reporter uses a template to format and
%    number the caption and position it relative to the image. The
%    caption is automatically numbered and positioned beneath the image
%    You can customize the format by specifying a custom template or by
%    overriding the template programmatically, using the reporter's
%    properties.
%
%    image = FormalImage(source) creates an image reporter that adds
%    the image specified by the image source to a report. The image
%    source can be a file specified by file system path or a DOM Image
%    object.
%
%    image = FormalImage('p1', v1, 'p2', v2,...) creates an image
%    reporter and sets its properties (p1, p2, ...) to the specified
%    values (v1, v2, ...).
%
%    FormalImage properties:
%      Image           - Image source
%      Caption         - Image caption
%      Width           - Image width
%      Height          - Image height
%      ScaleToFit      - Scale the image to fit a page or table entry
%      Map             - Map of hyperlink areas (HTML and PDF only)
%      TemplateSrc     - Template source
%      TemplateName    - Template name
%      LinkTarget      - Hyperlink target for image
%
%    FormalImage methods:
%      getImageReporter       - Get formal image image source reporter
%      getCaptionReporter     - Get formal image caption reporter
%      getClassFolder         - Get location of folder that contains this class
%      createTemplate         - Copy the default formal image template
%      customizeReporter      - Subclasses FormalImage for customization
%      getImpl                - Get DOM implementation for this reporter
%
%    Example:
%         % Create a report
%         report = mlreportgen.report.Report("output","pdf");
%
%         % Create and add a chapter reporter to the report
%         chapter = mlreportgen.report.Chapter();
%         chapter.Title = "Formal Image Reporter Example";
%
%         % Create and add a formal image reporter to the report
%         image = mlreportgen.report.FormalImage();
%         image.Image = which("ngc6543a.jpg");
%         image.Caption = "Cat's Eye Nebula or NGC 6543";
%         image.Height = "5in";
%         append(chapter,image);
%         append(report,chapter);
%
%         % Close and view the output report
%         close(report);
%         rptview(report);
%
%   See also mlreportgen.dom.Image

     
    %   Copyright 2017-2023 The MathWorks, Inc.

    methods
        function out=FormalImage
        end

        function out=appendCaption(~) %#ok<STOUT>
            % Updates the caption of this FormalImage reporter, so that the
            % caption specified in the Caption property of this reporter appear
            % before the new caption specified by the newCaption
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template=mlreportgen.report.FormalImage.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the FormalImage reporter
            %    template specified by type at the location specified by templatePath.
            %    You can use this method to create a copy of a default FormalImage
            %    reporter template to serve as a starting point for creating your own
            %    custom template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % classfile = mlreportgen.report.FormalImage.customizeReporter(toClasspath)
            %    is a static method that creates an empty class derived from the
            %    FormalImage reporter class with the name toClasspath. You can use the
            %    generated class as a starting point for creating your own custom
            %    version of the FormalImage reporter.
            %
            %    For example:
            %    mlreportgen.report.FormalImage.customizeReporter("path_folder/MyFormalImage.m")
            %    mlreportgen.report.FormalImage.customizeReporter("+myApp/@FormalImage")
        end

        function out=getCaptionReporter(~) %#ok<STOUT>
            % reporter = getCaptionReporter(image) returns a reporter that
            % generates the formal image caption based on the Caption property,
            % which can be any MATLAB or DOM object that can be appended to
            % a DOM Paragraph. The Caption formats override any corresponding
            % formats in the template. Use this method to override the
            % image's default caption formats.
            %
            % See also mlreportgen.report.FormalImage.Caption
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = getClassFolder() return the folder location which contains this class.
        end

        function out=getImageReporter(~) %#ok<STOUT>
            % reporter = getImageReporter(image, report) returns a reporter that
            % generates a formal image based on the Image property, which
            % can be either the image path or a DOM Image. The Image format
            % overrides any corresponding format in the image template. Use
            % this method to override the image's default image template.
            %
            % See also mlreportgen.report.FormalImage.Image
        end

        function out=getTranslations(~) %#ok<STOUT>
            % translations = getTranslations() returns a persintent map with this reporter
            %     translations
        end

    end
    properties
        % Caption Caption of this formal image
        %    Specifies the text of the image caption. The value of this
        %    property may be a
        %        - MATLAB string
        %        - character array
        %        - DOM object
        %        - 1xN or Nx1 array of strings or DOM objects
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          and/or DOM objects
        %        - Hole reporter returned by getCaptionReporter
        %
        %    If the value of this property is inline content, i.e., content
        %    that can fit in a paragraph, the reporter uses a template
        %    stored in its template library to format the caption. The
        %    template automatically numbers the caption as follows. If the
        %    image is in a numbered chapter, a string of the form 'Figure
        %    N.M. ' prefixes the caption text, where N is the number of the
        %    chapter and M is the number of the figure in the chapter. For
        %    example, the prefix for the third image in the second chapter
        %    of the report is Figure 2.3. A prefix of the form 'Figure N. '
        %    precedes the caption text in unnumbered chapters, where N is 1
        %    for the first image in the report, 2 for the second image,
        %    etc. In many non-English locales, the caption prefix is
        %    translated to the language and format of the locale. See
        %    mlreportgen.report.Report.Locale for a list of translated
        %    locales.
        %
        %    Examples
        %
        %    % Use default caption formatting
        %    import mlreportgen.report.*
        %    image = FormalImage();
        %    image.Caption = 'System Design Description';
        %
        %    % Use default caption format but change color to red
        %    import mlreportgen.dom.*
        %    import mlreportgen.report.*
        %    image = FormalImage();
        %    text = Text('System Design Description');
        %    text.Color = 'red';
        %    image.Caption = text;
        %
        %    % Override default caption format
        %    import mlreportgen.dom.*
        %    import mlreportgen.report.*
        %    image = FormalImage();
        %    para = Paragraph('System Design Description');
        %    para.Style = {HAlign('left'), FontFamily('Arial'), ...
        %    FontSize('24pt'), Color('white'), BackgroundColor('blue'), ...
        %    OuterMargin('0in', '0in', '.5in', '1in'),HAlign('center')};
        %    image.Caption = para;
        %
        %    See also mlreportgen.report.FormalImage.getCaptionReporter
        Caption;

        % Height Height of this image
        %    The value of this property must be a string or a character
        %    array having the format valueUnits where Units is an
        %    abbreviation for the units in which the size is expressed. The
        %    following abbreviations are valid:
        %
        %    Abbreviation  Units
        %
        %    px            pixels
        %    cm            centimeters
        %    in            inches
        %    mm            millimeters
        %    pi            picas
        %    pt            points
        %
        %    This property applies only to a formal image specified by an image
        %    path as the image source. If you do not set the formal image's
        %    width, the width is scaled to preserve the aspect ratio of the image.
        %
        %    See also mlreportgen.report.FormalImage.Image,
        %    mlreportgen.report.FormalImage.Width
        Height;

        % Image Source of the image to be reported
        %    The value of this property may be a  string or character array
        %    that specifies an image path or it may be a DOM Image object.
        %
        %    Supported image formats are:
        %
        %    .bmp - Bitmap image
        %    .gif - Graphics Interchange format
        %    .jpg - JPEG image
        %    .png - PNG image
        %    .emf - Enhanced metafile, supported only in DOCX output on
        %           Windows platform
        %    .svg - Scalable Vector Graphics, not supported in DOCX output
        %    .tif - Tag Image File format, not supported in HTML output
        %    .pdf - PDF image
        %
        %    This reporter inserts the image in a paragraph whose style
        %    is specified by the reporter's template. The paragraph style
        %    determines the alignment and spacing of the image relative to
        %    its caption. You can customize the alignment and spacing by
        %    customizing the reporter's template (see the FormalImageImage
        %    template in the reporter's template library) or you can
        %    override the alignment and spacing by wrapping the image in
        %    a paragraph yourself and assigning the paragraph as the
        %    value of this property.
        %
        %    See also mlreportgen.report.FormalImage.getImageReporter
        Image;

        % Map Map of hyperlink areas in this formal image (HTML and PDF only)
        %    The value of this property must be an object of type
        %    mlreportgen.dom.ImageMap, that denotes the map of image areas,
        %    which are areas in the formal image that you can click to open
        %    content in a browser or to navigate to another location in the
        %    same page. Define areas using mlreportgen.dom.ImageArea and
        %    append them to the map.
        %
        %    Example
        %
        %      import mlreportgen.report.*
        %      report = Report('test', 'pdf');
        %      image = FormalImage(which('ngc6543a.jpg'));
        %      area = mlreportgen.dom.ImageArea('https://www.google.com', 'Google', 0, 0, 100, 100);
        %      map = mlreportgen.dom.ImageMap;
        %      append(map, area);
        %      image.Map = map;
        %      add(report, image);
        %      close(report);
        %      rptview(report);
        %
        %    See also mlreportgen.report.FormalImage.Image,
        %    mlreportgen.dom.ImageMap, mlreportgen.dom.ImageArea
        Map;

        % ScaleToFit Scale this formal image to fit a page or table entry
        %    This property specifies whether to scale the formal image to
        %    fit between the margins of a Microsoft Word or PDF page or
        %    table entry. The value of this property is logical (true or
        %    false).
        %
        %    See also mlreportgen.report.FormalImage.Image,
        %    mlreportgen.dom.ScaleToFit
        ScaleToFit;

        % Width Width of this image
        %    The value of this property must be a string or a character
        %    array having the format valueUnits where Units is an
        %    abbreviation for the units in which the size is expressed. The
        %    following abbreviations are valid:
        %
        %    Abbreviation  Units
        %
        %    px            pixels
        %    cm            centimeters
        %    in            inches
        %    mm            millimeters
        %    pc            picas
        %    pt            points
        %    %             percent
        %
        %    This property applies only to a formal image specified by an image
        %    path as the image source. If you do not set the formal image's
        %    height, the height is scaled to preserve the aspect ratio of the image.
        %
        %    See also mlreportgen.report.FormalImage.Image,
        %    mlreportgen.report.FormalImage.Height
        Width;

    end
end
