classdef Equation< mlreportgen.report.Reporter & mlreportgen.report.mixin.SnapshotMaker
% Equation Create an equation
%
%    equation = Equation() creates an empty equation reporter. You can
%    set its properties to generate an equation.
%
%    equation = Equation(markup) formats the equation represented by
%    the specified LaTeX markup string and adds it to a report as an
%    image of the formatted equation. The image is embedded in an empty, 
%    centered paragraph by default. It can optionally be appended in 
%    line with other text in a paragraph. The image and therefore the
%    equation can be scaled to any size. You may use any LaTeX markup supported
%    by the Interpreter property of a MATLAB text object. The snapshot
%    image of the equation is stored in the report's temporary
%    directory from which it is copied into the report when the report
%    is closed and are then deleted by default. You can use the
%    report's Debug property to keep the image files from being
%    deleted.
%
%    equation = Equation('p1', v1, 'p2', v2,...) creates an equation
%    reporter and sets the equation reporter's properties, p1, p2, ...,
%    to the values specified by v1, v2, ...
%
%
%    Equation properties:
%      Content            - LaTeX markup for equation
%      FontSize           - Font size of formatted equation
%      Color              - Font color of formatted equation
%      BackgroundColor    - Background color of formatted equation
%      DisplayInline      - Display as an inline equation
%      SnapshotFormat     - File format of snapshot
%      UseDirectRenderer  - Whether to use direct equation renderer
%      TemplateSrc        - Equation reporter's template source
%      TemplateName       - Equation reporter's template name
%      LinkTarget         - Hyperlink target for Equation snapshot
%
%    Equation methods:
%      getContentReporter - Get equation content reporter
%      createTemplate     - Copy the default equation template
%      customizeReporter  - Subclasses Equation for customization
%      getSnapshotImage   - Get a snapshot of a rendered equation
%      getImpl            - Get DOM implementation for this reporter
%      getClassFolder     - Get class definition folder
%
%    Example
%
%    import mlreportgen.report.*
%    rpt = Report('equation', 'docx');
%    ch = Chapter('Title', 'Equation');
%    add(ch, Equation('\int_{0}^{2} x^2\sin(x) dx'));
%    add(rpt, ch);
%    close(rpt);
%    rptview(rpt);
%
%    Example
%
%    % Create a left aligned, numbered equation.
%
%    import mlreportgen.report.*
%    import mlreportgen.dom.*
%    rpt = Report('equation', 'html');
%    ch = Chapter('Title', 'Equation');
%    eq = Equation('\int_{0}^{2} x^2\sin(x) dx');
%    eq.FontSize = 12;
%    p = Paragraph('Eq 1: ');
%    p.Bold = true;
%    eqImg = Image(getSnapshotImage(eq, rpt));
%    t = Table({p, eqImg});
%    add(ch, t);
%    add(rpt, ch);
%    close(rpt);
%    rptview(rpt);
%
%    See also mlreportgen.report.Equation.getSnapshotImage,
%    mlreportgen.report.Report.Debug

     
    %    Copyright 2019-2023 The MathWorks, Inc.

    methods
        function out=Equation
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.Equation.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the Equation reporter
            %    template specified by type at the location specified by templatePath.
            %    You can use this method to create a copy of a default Equation
            %    reporter template to serve as a starting point for creating your own
            %    custom template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % classfile = mlreportgen.report.Equation.customizeReporter(toClasspath)
            %    is a static method that creates an empty class derived from the
            %    Equation reporter class with the name toClasspath. You can use the
            %    generated class as a starting point for creating your own custom
            %    version of the Equation reporter.
            %
            %    For example:
            %    mlreportgen.report.Equation.customizeReporter("path_folder/MyEquation.m")
            %    mlreportgen.report.Equation.customizeReporter("+myApp/@Equation")
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = getClassFolder() return the folder location which contains this
            % class.
        end

        function out=getContentReporter(~) %#ok<STOUT>
            % content = getContentReporter(equation, rpt) returns a hole reporter used
            %    to fill the Content hole in the Equation reporter's template. The hole
            %    reporter contains an image of the formated equation generated from the
            %    LaTeX markup specified by the Equation reporter's Content property.
            %    You can use this method to override the format specified by the
            %    Content hole reporter.
        end

        function out=getImpl(~) %#ok<STOUT>
            % impl =  getImpl(this, rpt) returns a DOM Image object when 
            % DisplayInline = true, else it returns a Document part
        end

        function out=getSnapshotImage(~) %#ok<STOUT>
            % mlreportgen.report.Equation.getSnapshotImage
            % imgpath = getSnapshotImage(equation, rpt) creates an image
            % file containing the formatted equation and returns a path to
            % the image file. The image file is a scalable vector graphics
            % file of type .svg for HTML, PDF, and DOCX output on all platforms.
            %
            % See also mlreportgen.report.Equation
        end

    end
    properties
        % BackgroundColor Background color of rendered equation
        %
        % Must be empty or a character array or string that specifies the
        % name of the color of the background of the rendered equation. The
        % color name may be any of the long or short color names supported
        % by the Color property of the MATLAB text object. Empty specifies
        % white.
        %
        % Example
        %
        % import mlreportgen.report.*
        % rpt = Report('equation', 'docx');
        % ch = Chapter('Title', 'Equation');
        % eq = Equation;
        % eq.Content = '\int_{0}^{2} x^2\sin(x) dx';
        % eq.FontSize = 14; % Equation size = 14 points
        % eq.Color = 'b';
        % eq.BackgroundColor = 'y';
        % add(ch, eq);
        % add(rpt, ch);
        % close(rpt);
        % rptview(rpt);
        BackgroundColor;

        % Color Font color of rendered equation
        %
        % Must be empty or a character array or string that specifies the
        % name of the color of the rendered equation. The color name may
        % be any of the long or short color names supported by the Color
        % property of the MATLAB text object. Empty specifies black.
        %
        % Example
        %
        % import mlreportgen.report.*
        % rpt = Report('equation', 'docx');
        % ch = Chapter('Title', 'Equation');
        % eq = Equation;
        % eq.Content = '\int_{0}^{2} x^2\sin(x) dx';
        % eq.FontSize = 14; % Equation size = 14 points
        % eq.Color = 'blue';
        % add(ch, eq);
        % add(rpt, ch);
        % close(rpt);
        % rptview(rpt);
        Color;

        % Content LaTeX markup for equation
        %
        % Must be a character array or string containing LaTeX markup for
        % the equation to be displayed.
        %
        % Example
        %
        % import mlreportgen.report.*
        % rpt = Report('equation', 'docx');
        % ch = Chapter('Title', 'Equation');
        % eq = Equation;
        % eq.Content = '\int_{0}^{2} x^2\sin(x) dx';
        % add(ch, eq);
        % add(rpt, ch);
        % close(rpt);
        % rptview(rpt);
        Content;

        % DisplayInline Display equation in line
        %
        % If false (default), this property causes the reporter to create 
        % a document part containing an image of the equation wrapped in a 
        % paragraph. The reporter then adds the document part to a report, 
        % resulting in an equation on a separate line. You can use this 
        % option only with block holes.
        %
        % If true, this property causes the reporter to add the equation 
        % image to the report without wrapping it in a paragraph. You can 
        % use this option to add the equation to an inline hole in a 
        % report, i.e., a hole in the text of a template paragraph. The  
        % result is an equation embedded in a line of the paragraph's text.
        % This option also allows you to use the reporter's getImpl method 
        % to get the equation image. You can then add the image, 
        % i.e., the equation, to a paragraph along with text and other 
        % inline objects, resulting in a programmatically generated inline
        % equation.
        %
        % See also mlreportgen.report.Equation.getImpl
        % Example
        %
        % import mlreportgen.report.*
        % import mlreportgen.dom.*
        % rpt = Report("equation", "docx");
        % eq = Equation("\int_{0}^{2} x^2\sin(x) dx");
        % eq.DisplayInline = true;
        % img = getImpl(eq, rpt); 
        % p = Paragraph("Here is an inline equation:");
        % append(p, img);
        % append(p, "More text")
        % add(rpt, p);
        % close(rpt);
        % rptview(rpt);
        DisplayInline;

        % FontSize Font size of formatted equation
        %
        % Must be empty or an integer value that specifies the font size of
        % the rendered equation in points. Empty specifies a font size of
        % 10.
        %
        % Example
        %
        % import mlreportgen.report.*
        % rpt = Report('equation', 'docx');
        % ch = Chapter('Title', 'Equation');
        % eq = Equation;
        % eq.Content = '\int_{0}^{2} x^2\sin(x) dx';
        % eq.FontSize = 14; % Equation size = 14 points
        % add(ch, eq);
        % add(rpt, ch);
        % close(rpt);
        % rptview(rpt);
        FontSize;

        % SnapshotFormat File format of the rendered equation snapshot image file
        %    The value of this property is a string or character array that
        %    specifies the file format of the rendered equation snapshot. Supported
        %    formats:
        %
        %    svg  - Scalable Vector Graphics (default)
        %    png  - PNG image
        %    emf  - Enhanced metafile, supported only in DOCX output on
        %           Windows platform
        %    Example
        %
        % import mlreportgen.report.*
        % import mlreportgen.dom.*
        % rpt = Report("equation", "docx");
        % p = Paragraph("Here is an equation:");
        % eq = Equation("\int_{0}^{2} x^2\sin(x) dx");
        % eq.SnapshotFormat = "emf";
        % img = Image(getSnapshotImage(eq, rpt));
        % append(p, img);
        % add(rpt, p);
        % close(rpt);
        % rptview(rpt);
        SnapshotFormat;

        % UseDirectRenderer Whether to use direct equation renderer
        %    If this property is true, the reporter renders an equation
        %    directly instead of using the Figure window equation renderer.
        %    The Live Editor and Simulink editor also use the direct
        %    equation renderer. As a result, this option ensures that
        %    equations appear the same in a report as they do in the Live
        %    Editor and in Simulink annotations.
        %
        %    Note: the direct renderer provide better support for equation
        %    markup than does the Figure window renderer. However, it does
        %    not support SVG output or equation background colors. If these
        %    features are important in your application, use the Figure
        %    window renderer (the default).
        UseDirectRenderer;

    end
end
