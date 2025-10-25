classdef ListOfFigures< mlreportgen.report.Reporter
%mlreportgen.report.ListOfFigures Create a report List Of Figures (LOF)
%    lof = ListOfFigures() creates a reporter that generates a report LOF
%    section based on a default template that defines the section's
%    appearance and page layout. The LOF section contains a default section
%    title and a LOF element that specifies the location of a list of
%    figures to be generated, depending on report output type, as follows:
%
%      HTML - A JavaScript copied from the report's template to the report
%             generates the LOF when the report is opened in a browser. The
%             script generates the LOF as a collapsible tree whose entries
%             consist of the hyperlinked contents of the report's image 
%             caption elements. 
%
%      DOCX - The Report Generator's rptview function commands Word to
%             generate the LOF after it opens the report in Word. If you
%             open a report in Word directly, i.e., without using rptview,
%             you must update the report document yourself to generate the
%             LOF. The LOF consists of a two-column table whose first
%             column contains the hyperlinked contents of report's image  
%             caption. The LOF's second column contains the number of the
%             page in which the corresponding image caption occurs.
%
%      PDF  - The Report Generator uses a third-party application (AHFormatter) to
%             generate the LOF as part of the generate PDF document. The
%             FOP generates the LOF in a manner similar to the way Word
%             generates a LOF for a Word document.
%
%    lof = ListOfFigures(title) creates a LOF having the specified 
%    LOF section title.
%
%    lof = mlreportgen.report.ListOfFigures(p1, v1, p2, v2,...) creates a
%    LOF and sets its properties (p1, p2, ...) to the specified
%    values (v1, v2, ...).
%
%    ListOfFigures properties:
%      Title           - ListOfFigures title
%      LeaderPattern   - ListOfFigures LeaderPattern
%      Layout          - Page layout of List Of Figures
%      TemplateSrc     - Source of this reporter's template
%      TemplateName    - Template name in source template library
%      LinkTarget      - Hyperlink target for List Of Figures
%
%    ListOfFigures methods:
%      getTitleReporter  - Get List Of Figures title reporter
%      getClassFolder    - Get location of folder that contains this class
%      createTemplate    - Copy the default List Of Figures template
%      customizeReporter - Subclasses ListOfFigures for customization
%
%
%    Example
%
%     import mlreportgen.report.*
%     import mlreportgen.dom.*
% 
%     rpt = Report('Report with List of Figures', "docx");
%     % rpt = Report('Report with List of Figures', "html");
%     % rpt = Report('Report with List of Figures', "pdf");
%     % rpt = Report('Report with List of Figures', "html-file");
% 
%     lof = ListOfFigures;
%     lof.Title = Text('My LOF');
%     lof.Title.Color = 'green';
%     add(rpt,lof);
% 
%     image = FormalImage();
%     image.Image = which('ngc6543a.jpg');
%     image.Caption = 'Cat''s Eye Nebula or NGC 6543';
%     image.Height = '5in';
%     add(rpt,image);
% 
%     close(rpt);
%     rptview(rpt);
%    
%    See also rptview, mlreportgen.report.Chapter,
%    mlreportgen.report.Section, mlreportgen.dom.Heading,
%    mlreportgen.dom.Paragraph

 
%   Copyright 2020-2023 The MathWorks, Inc.

    methods
        function out=ListOfFigures
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.ListOfFigures.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the
            %    ListOfFigures template specified by type at the location
            %    specified by templatePath. You can use this method to
            %    create a copy of the default ListOfFigures template to
            %    serve as a starting point for creating your own custom
            %    template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % path = mlreportgen.report.ListOfFigures.customizeReporter(path)
            %    is a static method that creates a class definition file
            %    that defines a subclass of
            %    mlreportgen.report.ListOfFigures
            %    class. You can use this file as a starting point for
            %    defining a custom LOF class. The path argument is a
            %    string that specifies the path of the class definition
            %    file to be created.
            %
            %    Example
            %
            %    mlreportgen.report.ListOfFigures.customizeReport("+myApp/@MyListOfFigures")
            %    defines a ListOfFigures subclass named myApp.MyListOfFigures.
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = getClassFolder() return the folder location which contains this class.
        end

        function out=getTitleReporter(~) %#ok<STOUT>
            %getTitleReporter Gets the LOF Title reporter
            % reporter = getTitleReporter(lof) returns a reporter that the
            % ListOfFigures reporter uses to format the content specified
            % by the value of its Title property. You can use this reporter
            % to customize the title alignment, position, and appearance.
            % See the mlreportgen.report.TitlePage help for information
            % on customizing reporter content. The help is specific to
            % title pages but applies to reporter content generally.
            %
            % See also mlreportgen.report.ListOfFigures.Title,
            % mlreportgen.report.TitlePage
        end

    end
    properties
        % Layout Page layout of this LOF
        %    The value of this property must be an object of type
        %    mlreportgen.report.ReportLayout that allows you to override
        %    some properties of the LOF section's default layout such as
        %    its page orientation.
        %
        %    See also mlreportgen.report.ReporterLayout
        Layout;

        % LeaderPattern List Of Figures (LOF) property specifies the leader pattern to be used in the 
        %    list of figures.
        %
        %    Valid values are:
        %
        %    Value               DESCRIPTION
        %    'dots' or '.'       leader of dots
        %    'space' or ' '      leader of spaces
        %
        %    Example
        %
        %    lof = mlreportgen.report.ListOfFigures;
        %    lof.LeaderPattern = '.';
        %    lof.LeaderPattern = ' ';
        LeaderPattern;

        % Title List Of Figures (LOF) section title
        %    Specifies the content of the LOF section title. You can use any
        %    of the following to specify the title content
        %
        %        - MATLAB string
        %        - character array
        %        - DOM object
        %        - 1xN or Nx1 array of strings or DOM objects
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          and/or DOM objects
        %        - ListOfFiguresTitle reporter
        %
        %    Example
        %
        %    lof = mlreportgen.report.ListOfFigures;
        %    lof.Title = mlreportgen.dom.Text('List Of Figures');
        %    lof.Title.FontFamily = 'Helvetica';
        Title;

    end
end
