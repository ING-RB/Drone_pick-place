classdef Axes< mlreportgen.report.MATLABGraphicsContainer & mlreportgen.report.Reporter
%mlreportgen.report.Axes Create an axes reporter
%
%   axes = Axes() creates an empty axes reporter. You can use
%   the reporter's properties to specify the axes source, caption,
%   height, width, etc.
%
%   axes = Axes(source) creates a reporter that adds the axes
%   specified by source. Source must be an axes handle.
%
%   axes = Axes(p1=v1, p2=v2,...) creates a axes reporter and
%   sets its properties (p1, p2, ...) to the specified values (v1, v2,
%   ...).
%
%   Axes properties:
%      Snapshot                 - Image of the axes
%      Source                   - Axes source
%      SnapshotFormat           - File format of the axes snapshot
%      Scaling                  - Scaling of the snapshot image
%      Height                   - Snapshot image height for custom scaling
%      Width                    - Snapshot image width for custom scaling
%      PreserveBackgroundColor  - Preserve axes snapshot background color
%      Theme                    - Graphics theme of printed axes
%      TemplateSrc              - Axes reporter's template source
%      TemplateName             - Axes reporter's template name
%      LinkTarget               - Hyperlink target for axes snapshot
%
%   Axes methods:
%      getSnapshotImage     - Get snapshot of specified axes
%      getClassFolder       - Get class definition folder
%      createTemplate       - Copy the default axes template
%      customizeReporter    - Subclasses Axes for customization
%      getImpl              - Get DOM implementation for this reporter
%
%   Example:
%
%
%     % Create a report
%     rpt = mlreportgen.report.Report("Report with Axes","pdf");
%
%     % Create a chapter
%     chapter = mlreportgen.report.Chapter("Axes");
%
%     % Create an axes
%     ax1 = axes(Position=[0.1 0.1 0.7 0.7]);
%     x1 = linspace(0,10,100);
%     y1 = sin(x1);
%     plot(ax1,x1,y1);
%     axesRpt1 = mlreportgen.report.Axes(ax1);
%
%     % Create an axes
%     ax2 = axes(Position=[0.65 0.65 0.28 0.28]);
%     ax2.XLim = [1 2];
%     x2 = linspace(0,5,100);
%     y2 = sin(x2);
%     plot(ax2,x2,y2);
%     axesRpt2 = mlreportgen.report.Axes(ax2);
%
%     % Add axes to the chapter and chapter to the report
%     add(chapter,axesRpt1);
%     add(chapter,axesRpt2);
%     add(rpt,chapter);
%
%     % Close and view the output report
%     close(rpt);
%     rptview(rpt);
%
%   See also mlreportgen.report.Axes.getSnapshotImage,
%   mlreportgen.report.Figure, mlreportgen.report.Report.Debug

 
    %   Copyright 2021-2024 The MathWorks, Inc.

    methods
        function out=Axes
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.Axes.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the Axes reporter template
            %    specified by type at the location specified by templatePath. You can
            %    use this method to create a copy of a default Axes reporter template
            %    to serve as a starting point for creating your own custom template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % classfile = mlreportgen.report.Axes.customizeReporter(toClasspath)
            %    is a static method that creates an empty class derived from the Axes
            %    reporter class with the name toClasspath. You can use the generated
            %    class as a starting point for creating your own custom version of the
            %    Axes reporter.
            %
            %    For example:
            %    mlreportgen.report.Axes.customizeReporter("path_folder/MyAxes.m")
            %    mlreportgen.report.Axes.customizeReporter("+myApp/@Axes")
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = mlreportgen.report.Axes.getClassFolder() return the
            % folder location that contains this class.
        end

        function out=getClonedFigureFile(~) %#ok<STOUT>
            % Get figure file for creating figure snapshot
        end

        function out=getImageFormat(~) %#ok<STOUT>
            % Get image format based on SnapshotFormat property.
        end

        function out=getImpl(~) %#ok<STOUT>
            % Set the LinkTarget property for the reporter
        end

        function out=getSnapshotImage(~) %#ok<STOUT>
            % mlreportgen.report.Axes.getSnapshotImage
            % imgpath = getSnapshotImage(axesReporter,rpt) creates an
            % image of the axes window specified by axesReporter and
            % returns a path to a file containing the image. You can use
            % this method to customize the layout of the axes in your
            % report.
            %
            % See also mlreportgen.report.Axes
        end

        function out=getSnapshotImageImpl(~) %#ok<STOUT>
        end

        function out=getWebAppSnapshotImageImpl(~) %#ok<STOUT>
            % Use exportgraphics to get snapshot of axes. This function
            % does not create any new figures.
        end

    end
    properties
        % Height Axes snapshot image height for custom scaling
        %   The value of this property is a character vector or string scalar
        %   having the format valueUnits, where Units is an abbreviation for
        %   the units in which the size is expressed. The following abbreviations
        %   are valid:
        %
        %   Abbreviation    Units
        %   px              pixels
        %   cm              centimeters
        %   in              inches
        %   mm              millimeters
        %   pc              picas
        %   pt              points
        %
        %   See also mlreportgen.report.Axes.Scaling
        Height;

        HierNumberedCaptionTemplateName;

        ImageTemplateName;

        NumberedCaptionTemplateName;

        % PreserveBackgroundColor  Preserve axes snapshot background color
        %   The value of this property is a logical that specifies whether
        %   to preserve axes background color. If this property is true,
        %   the axes snapshot background color will be the same as the
        %   axes, and this reporter's Theme property is ignored. If this
        %   property is false (default), the axes snapshot background color
        %   is determined by this reporter's Theme property.
        PreserveBackgroundColor;

        % Scaling Scaling options for the axes snapshot image
        %   The Axes reporter uses the axes' PaperPosition property
        %   to specify the height and width of the snapshot generated
        %   from the axes.
        %
        %   auto    - (default) For PDF & DOCX outputs, the axes
        %             snapshot is resized, if necessary, to fit between the
        %             page margins specified by the report layout,
        %             preserving the axes' aspect ratio. First, the
        %             snapshot is resized to fit between the left and
        %             right margins. It is resized again if necessary to
        %             fit between the top and bottom margins with one inch
        %             to spare for a caption. For HTML output, there is no
        %             scaling.
        %   custom  - Resizes the axes snapshot image to the dimensions
        %             specified by this reporter's Height and Width
        %             properties.
        %   none    - No resizing.
        %
        %   Note: the "auto" and "custom" options use the MATLAB print
        %   command to resize the axes. If the axes is too large to fit
        %   legibly in the specified space, the print command crops the
        %   snapshot image. To avoid cropping, you can specify "none" as
        %   the value of this option and use the Snapshot reporter to size
        %   the axes image. This reduces the size of the text with the
        %   rest of the image and may require a user to zoom the image in a
        %   viewer to discern fine detail.
        %
        %   See also mlreportgen.report.Axes.Height,
        %   mlreportgen.report.Axes.Width
        Scaling;

        % Snapshot Image of the axes to be included in a report
        %   This is a mlreportgen.report.FormalImage object that
        %   the Axes reporter uses to insert the axes into a report.
        %   This axes reporter initializes this property. You should not
        %   reset it. You can use the FormalImage object's properties to
        %   provide a caption for the snapshot.
        %
        %   Example:
        %
        %     % Create a report
        %     rpt = mlreportgen.report.Report("Report with Axes","pdf");
        %
        %     % Create a chapter
        %     chapter = mlreportgen.report.Chapter("Axes");
        %
        %     % Create an axes
        %     ax1 = axes(Position=[0.1 0.1 0.7 0.7]);
        %     x1 = linspace(0,10,100);
        %     y1 = sin(x1);
        %     plot(ax1,x1,y1);
        %     ax1.Color = "yellow";
        %
        %     axesRpt = mlreportgen.report.Axes(ax1);
        %
        %     % Add a caption
        %     axesRpt.Snapshot.Caption = "Sample axes";
        %
        %     % Add axes to the chapter and chapter to the report
        %     append(chapter,axesRpt);
        %     append(rpt,chapter);
        %
        %     % Close and view the output report
        %     close(rpt);
        %     rptview(rpt);
        Snapshot;

        % SnapshotFormat Snapshot image format
        %   The value of this property is a string scalar or character
        %   vector that specifies the file format of the axes snapshot. The
        %   default value of this property is "auto", which automatically
        %   chooses the format based on these rules:
        %       - If the reporter is not used in a deployed web
        %       application, the SnapshotFormat is "svg".
        %       - If the reporter is used in a deployed web application and
        %       the output type is PDF, the SnapshotFormat is "pdf".
        %       - If the reporter is used in a deployed web application on
        %       a Windows server and the output type is DOCX, the
        %       SnapshotFormat is "emf".
        %       - For all other cases, the SnapshotFormat is "png".
        %
        %   Supported formats are:
        %       auto - Automatically selects format based on report type
        %              and context in which this reporter is used
        %       svg  - Scalable Vector Graphics, not supported in deployed
        %              web applications
        %       jpg  - JPEG image
        %       png  - PNG image
        %       emf  - Enhanced metafile, supported only in DOCX output on
        %              Windows platform
        %       tif  - Tag Image File format, not supported in HTML output
        %       pdf  - PDF Image, supported only in PDF output
        SnapshotFormat;

        % Source Source of the axes to be reported
        %   The value of this property must be an axes handle.
        Source;

        % Theme  Graphics theme of printed axes
        %   Graphics theme to use when printing the snapshot. Acceptable
        %   values are:
        %
        %   light   -  (default) Prints the axes with a white background and
        %              dark-colored graph lines, labels, etc.
        %   dark    -  Prints the axes with a dark-colored background and
        %              light-colored graph lines, labels, etc.
        %
        %   Manually set graphics colors, except axes background color, are
        %   preserved, regardless of theme setting. If
        %   PreserveBackgroundColor is true, this property is ignored.
        Theme;

        % Width Axes snapshot image height for custom scaling
        %   The value of this property is a character vector or string scalar
        %   having the format valueUnits, where Units is an abbreviation for
        %   the units in which the size is expressed. The following abbreviations
        %   are valid:
        %
        %   Abbreviation    Units
        %   px              pixels
        %   cm              centimeters
        %   in              inches
        %   mm              millimeters
        %   pc              picas
        %   pt              points
        %
        %   See also mlreportgen.report.Axes.Scaling
        Width;

    end
end
