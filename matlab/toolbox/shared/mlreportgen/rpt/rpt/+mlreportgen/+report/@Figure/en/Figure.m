classdef Figure< mlreportgen.report.MATLABGraphicsContainer & mlreportgen.report.Reporter
%mlreportgen.report.Figure Create a figure reporter
%
%   fig = Figure() creates a reporter that makes a snapshot of the
%   figure currently open in MATLAB, i.e., the result of invoking gcf,
%   and adds it to a report. You can use the reporter's properties to
%   add a caption to the snapshot and specify its size. The snapshot
%   image is stored in the report's temporary directory from which it
%   is copied into the report when the report is closed and then
%   deleted by default. You can use the report's Debug property to
%   keep the image files from being deleted.
%
%   fig = Figure(source) creates a reporter that adds the figure
%   specified by source. Source may be a figure handle or the path
%   of a figure file.
%
%   fig = Figure('p1', v1, 'p2', v2,...) creates a figure reporter and
%   sets its properties (p1, p2, ...) to the specified values (v1, v2,
%   ...).
%
%   Figure properties:
%      Snapshot                 - Image of the figure
%      Source                   - Figure source
%      SnapshotFormat           - File format of the figure snapshot
%      Scaling                  - Scaling the snapshot image
%      Height                   - Snapshot image height for custom scaling
%      Width                    - Snapshot image width for custom scaling
%      PreserveBackgroundColor  - Preserve figure snapshot background color
%      Theme                    - Graphics theme of printed figure
%      TemplateSrc              - Figure reporter's template source
%      TemplateName             - Figure reporter's template name
%      LinkTarget               - Hyperlink target for figure snapshot
%
%   Figure methods:
%      getSnapshotImage     - Get snapshot of specified figure
%      getClassFolder       - Get class definition folder
%      createTemplate       - Copy the default figure template
%      customizeReporter    - Subclasses Figure for customization
%      getImpl              - Get DOM implementation for this reporter
%
%   Example:
%
%   % Create a report
%   rpt = mlreportgen.report.Report("peaks","pdf");
%
%   % Create a chapter
%   chapter = mlreportgen.report.Chapter("peaks");
%
%   % Create a figure
%   f = surf(peaks);
%   fig = mlreportgen.report.Figure(f);
%
%   % Add a caption
%   fig.Snapshot.Caption = "3-D shaded surface plot";
%
%   % Use custom scaling option with Height and Width to be
%   % 4 inches each
%   fig.Scaling = "custom";
%   fig.Height = "4in";
%   fig.Width = "4in";
%
%   % Add figure to the chapter and chapter to the report
%   append(chapter,fig);
%   append(rpt,chapter);
%
%   % Close and view the output report
%   close(rpt);
%   rptview(rpt);
%
%   Example:
%
%   % Create report
%   rpt = mlreportgen.report.Report("peaks","pdf");
%
%   % Create a chapter
%   chapter = mlreportgen.report.Chapter("Display two figures side by side");
%
%   % Create figure 1 snapshot
%   f1 = surf(peaks(20));
%   fig1 = mlreportgen.report.Figure(f1);
%   fig1.Scaling = "custom";
%   fig1.Width = "3in";
%   fig1.Height = "3in";
%   peaks20 = mlreportgen.dom.Image(getSnapshotImage(fig1,rpt));
%   peaks20.Width = "3in";
%   peaks20.Height = "3in";
%
%   % Create figure 2 snapshot
%   f2 = surf(peaks(40));
%   fig2 = mlreportgen.report.Figure(f2);
%   fig2.Scaling = "custom";
%   fig2.Width = "3in";
%   fig2.Height = "3in";
%   peaks40 = mlreportgen.dom.Image(getSnapshotImage(fig2,rpt));
%   peaks40.Width = "3in";
%   peaks40.Height = "3in";
%
%   % Create table
%   t = mlreportgen.dom.Table({peaks20, peaks40; "peaks(20)", "peaks(40)"});
%   append(chapter,t);
%   append(rpt,chapter);
%
%   % Close and view report
%   close(rpt);
%   rptview(rpt);
%
%   See also mlreportgen.report.Figure.getSnapshotImage,
%   mlreportgen.report.Report.Debug

     
    %   Copyright 2017-2024 The MathWorks, Inc.

    methods
        function out=Figure
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.Figure.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the Figure reporter template
            %    specified by type at the location specified by templatePath. You can
            %    use this method to create a copy of a default Figure reporter template
            %    to serve as a starting point for creating your own custom template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % classfile = mlreportgen.report.Figure.customizeReporter(toClasspath)
            %    is a static method that creates an empty class derived from the Figure
            %    reporter class with the name toClasspath. You can use the generated
            %    class as a starting point for creating your own custom version of the
            %    Figure reporter.
            %
            %    For example:
            %    mlreportgen.report.Figure.customizeReporter("path_folder/MyFigure.m")
            %    mlreportgen.report.Figure.customizeReporter("+myApp/@Figure")
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = getClassFolder() return the folder location which contains this class.
        end

        function out=getClonedFigureFile(~) %#ok<STOUT>
            % Get figure file for creating figure snapshot
        end

        function out=getSnapshotImage(~) %#ok<STOUT>
            % mlreportgen.report.Figure.getSnapshotImage
            % imgpath = getSnapshotImage(figReporter, rpt) creates an
            % image of the figure window specified by figReporter and
            % returns a path to a file containing the image. You can use
            % this method to customize the layout of figures in your
            % report.
            %
            % See also mlreportgen.report.Figure
        end

    end
    properties
        % Height Figure snapshot image height for custom scaling
        %   The value of this property is a string having the format
        %   valueUnits, where Units is an abbreviation for the units in
        %   which the size is expressed. The following abbreviations are
        %   valid:
        %
        %   Abbreviation    Units
        %   px              pixels
        %   cm              centimeters
        %   in              inches
        %   mm              millimeters
        %   pc              picas
        %   pt              points
        %
        %   See also mlreportgen.report.Figure.Scaling
        Height;

        HierNumberedCaptionTemplateName;

        ImageTemplateName;

        NumberedCaptionTemplateName;

        % PreserveBackgroundColor  Preserve figure snapshot background color
        %   The value of this property is a logical that specifies whether
        %   to preserve figure background color.  If this property is true,
        %   the figure snapshot background color is the same as the figure,
        %   and this reporter's Theme property is ignored. If this property
        %   is false (default), the figure snapshot background color is
        %   determined by this reporter's Theme property.
        PreserveBackgroundColor;

        % Scaling Scaling options for the figure snapshot image
        %   The scaling options uses the figure's PaperPosition property
        %   to specify the height and width of the snapshot generated 
        %   from the figure.
        %
        %   auto    - (default) For PDF & DOCX outputs, the figure 
        %             snapshot is resized, if necessary, to fit between the
        %             page margins specified by the report layout,
        %             preserving the figure's aspect ratio. First, the
        %             snapshot is resized to fit between the left and
        %             right margins. It is resized again if necessary to
        %             fit between the top and bottom margins with one inch
        %             to spare for a caption. For HTML output, there is no
        %             scaling.
        %   custom  - Resizes the figure snapshot image to the dimensions
        %             specified by this reporter's Height and Width
        %             properties.
        %   none    - No sizing is performed.
        %
        %    Example:
        %
        %       % Create a report
        %       rpt = mlreportgen.report.Report("peaks", "pdf");
        %
        %       % Create a chapter
        %       chapter = mlreportgen.report.Chapter("peaks");
        %
        %       % Create a figure
        %       f = surf(peaks);
        %       fig = mlreportgen.report.Figure(f);
        %
        %       % Use custom scaling option with Height and Width to be
        %       % 4 inches each
        %       fig.Scaling = "custom";
        %       fig.Height = "4in";
        %       fig.Width = "4in";
        %
        %       % Add figure to the chapter and chapter to the report
        %       add(chapter, fig);
        %       add(rpt, chapter);
        %
        %       % Close and view report
        %       rptview(rpt);
        %
        %   Note: the 'auto' and 'custom' options use the MATLAB print
        %   command to resize the figure. If the figure is too large to fit
        %   legibly in the specified space, the print command crops the
        %   snapshot image. To avoid cropping, you can specify 'none' as
        %   the value of this option and use the Snapshot reporter to size
        %   the figure image. This reduces the size of the text with the
        %   rest of the image and may require a user to zoom the image in a
        %   viewer to discern fine detail.
        %
        %   Example:
        %
        %     % Generate PDF report that illustrates visual difference
        %     % between print command-based sizing and snapshot image-based
        %     % resizing.
        %     import mlreportgen.report.*
        %
        %     % Create wide figure
        %     fig = figure();
        %     ax = axes(fig);
        %     plot(ax, rand(1,100));
        %
        %     pos = fig.Position;
        %     fig.Position = [pos(1) pos(2) 2*pos(3) pos(4)];
        %   
        %     rpt = Report('example', 'pdf');
        %   
        %     add(rpt, "Intrinsic figure size");
        %     figReporter0 = Figure(fig);
        %     figReporter0.Scaling = 'none';
        %     add(rpt, figReporter0);
        %   
        %     add(rpt, "Resized by print command");
        %     figReporter1 = Figure(fig);
        %     add(rpt, figReporter1);
        %   
        %     add(rpt, "Resized by snapshot reporter");
        %     figReporter2 = Figure(fig);
        %     figReporter2.Scaling = 'none';
        %     figReporter2.Snapshot.ScaleToFit = true;
        %     add(rpt, figReporter2);
        %   
        %     close(rpt);
        %     delete(fig)
        %     rptview(rpt);
        %
        %   See also mlreportgen.report.Figure.Height,
        %   mlreportgen.report.Figure.Width,
        Scaling;

        % Snapshot Image of the figure to be included in a report
        %   This is a reporter of mlreportgen.report.FormalImage class
        %   that this reporter uses to insert the figure into a report.
        %   This figure reporter initializes this property. You should not
        %   reset it. You can use the FormalImage object's properties to
        %   provide a caption for the snapshot.
        %
        %   Example:
        %
        %       % Create a report
        %       rpt = mlreportgen.report.Report("peaks", "pdf");
        %
        %       % Create a chapter
        %       chapter = mlreportgen.report.Chapter("peaks");
        %
        %       % Create a figure
        %       f = surf(peaks);
        %       fig = mlreportgen.report.Figure(f);
        %
        %       % Specify a caption
        %       fig.Snapshot.Caption = "3-D shaded surface plot";
        %
        %       % Add figure to the chapter and chapter to the report
        %       add(chapter, fig);
        %       add(rpt, chapter);
        %
        %       % Close and view report
        %       rptview(rpt);
        %
        %   See also mlreportgen.report.FormalImage
        Snapshot;

        % SnapshotFormat Snapshot image format
        %   The value of this property is a string or character array that
        %   specifies the file format of the figure snapshot. Supported
        %   formats:
        %
        %       svg -  Scalable Vector Graphics (default) 
        %       jpg -  JPEG image
        %       png -  PNG image
        %       emf -  Enhanced metafile, supported only in DOCX output on
        %              Windows platform
        %       tif -  Tag Image File format, not supported in HTML output
        %       pdf -  PDF Image
        SnapshotFormat;

        % Source Source of the figure to be reported
        %   The value of this property may be a figure handle or the path
        %   of a valid figure file or a valid graphics handle.
        Source;

        % Theme  Graphics theme of printed figure
        %   Graphics theme to use when printing the snapshot. Acceptable
        %   values are:
        %
        %   light   -  (default) Prints the figure with a white background and
        %              dark-colored graph lines, labels, etc.
        %   dark    -  Prints the figure with a dark-colored background and
        %              light-colored graph lines, labels, etc.
        %
        %   Manually set graphics colors, except figure and axes background
        %   colors, are preserved, regardless of theme setting. If
        %   PreserveBackgroundColor is true, this property is ignored.
        Theme;

        % Width Figure snapshot image height for custom scaling
        %   The value of this property is a string having the format
        %   valueUnits, where Units is an abbreviation for the units in
        %   which the size is expressed. The following abbreviations are
        %   valid:
        %
        %   Abbreviation    Units
        %   px              pixels
        %   cm              centimeters
        %   in              inches
        %   mm              millimeters
        %   pc              picas
        %   pt              points
        %
        %   See also mlreportgen.report.Figure.Scaling
        Width;

    end
end
