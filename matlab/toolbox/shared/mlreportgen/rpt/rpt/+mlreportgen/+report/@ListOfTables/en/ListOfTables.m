classdef ListOfTables< mlreportgen.report.Reporter
%mlreportgen.report.ListOfTables Create a report List of Tables (LOT)
%    lot = ListOfTables() creates a reporter that generates a report LOT
%    section based on a default template that defines the section's
%    appearance and page layout. The LOT section contains a default section
%    title and a LOT element that specifies the location of a list of
%    tables to be generated, depending on report output type, as follows:
%
%      HTML - A JavaScript copied from the report's template to the report
%             generates the LOT when the report is opened in a browser. The
%             script generates the LOT as a collapsible tree whose entries
%             consist of the hyperlinked contents of the report's table 
%             caption elements. 
%
%      DOCX - The Report Generator's rptview function commands Word to
%             generate the LOT after it opens the report in Word. If you
%             open a report in Word directly, i.e., without using rptview,
%             you must update the report document yourself to generate the
%             LOT. The LOT consists of a two-column table whose first
%             column contains the hyperlinked contents of report's table  
%             caption. The LOT's second column contains the number of the
%             page in which the corresponding table caption occurs.
%
%      PDF  - The Report Generator uses a third-party application (AHFormatter) to
%             generate the LOT as part of the generate PDF document. The
%             FOP generates the LOT in a manner similar to the way Word
%             generates a LOT for a Word document.
%
%    lot = ListOfTables(title) creates a LOT having the specified 
%    LOT section title.
%
%    lot = mlreportgen.report.ListOfTables(p1, v1, p2, v2,...) creates a
%    LOT and sets its properties (p1, p2, ...) to the specified
%    values (v1, v2, ...).
%
%    ListOfTables properties:
%      Title           - ListOfTables title
%      LeaderPattern   - ListOfTables LeaderPattern
%      Layout          - Page layout of List of Tables
%      TemplateSrc     - Source of this reporter's template
%      TemplateName    - Template name in source template library
%      LinkTarget      - Hyperlink target for List of Tables
%
%    ListOfTables methods:
%      getTitleReporter  - Get List of Tables title reporter
%      getClassFolder    - Get location of folder that contains this class
%      createTemplate    - Copy the default List of Tables template
%      customizeReporter - Subclasses ListOfTables for customization
%
%
%    Example
%
%     import mlreportgen.report.*
%     import mlreportgen.dom.*
% 
%     rpt = Report('Report with List of Tables', "docx");
%     % rpt = Report('Report with List of Tables', "html");
%     % rpt = Report('Report with List of Tables', "pdf");
%     % rpt = Report('Report with List of Tables', "html-file");
% 
%     lot = ListOfTables;
%     lot.Title = Text('My LOT');
%     lot.Title.Color = 'green';
%     add(rpt,lot);
% 
%     table = BaseTable(magic(5));
%     table.Title = 'Picture Gallery';
%     add(rpt,table);
% 
%     close(rpt);
%     rptview(rpt);
%    
%    See also rptview, mlreportgen.report.Chapter,
%    mlreportgen.report.Section, mlreportgen.dom.Heading,
%    mlreportgen.dom.Paragraph

 
%   Copyright 2020-2023 The MathWorks, Inc.

    methods
        function out=ListOfTables
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.ListOfTables.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the
            %    ListOfTables template specified by type at the location
            %    specified by templatePath. You can use this method to
            %    create a copy of the default ListOfTables template to
            %    serve as a starting point for creating your own custom
            %    template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % path = mlreportgen.report.ListOfTables.customizeReporter(path)
            %    is a static method that creates a class definition file
            %    that defines a subclass of
            %    mlreportgen.report.ListOfTables
            %    class. You can use this file as a starting point for
            %    defining a custom LOT class. The path argument is a
            %    string that specifies the path of the class definition
            %    file to be created.
            %
            %    Example
            %
            %    mlreportgen.report.ListOfTables.customizeReport("+myApp/@MyListOfTables")
            %    defines a ListOfTables subclass named myApp.MyListOfTables.
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = getClassFolder() return the folder location which contains this class.
        end

        function out=getTitleReporter(~) %#ok<STOUT>
            %getTitleReporter Gets the LOT Title reporter
            % reporter = getTitleReporter(lot) returns a reporter that the
            % ListOfTables reporter uses to format the content specified
            % by the value of its Title property. You can use this reporter
            % to customize the title alignment, position, and appearance.
            % See the mlreportgen.report.TitlePage help for information
            % on customizing reporter content. The help is specific to
            % title pages but applies to reporter content generally.
            %
            % See also mlreportgen.report.ListOfTables.Title,
            % mlreportgen.report.TitlePage
        end

    end
    properties
        % Layout Page layout of this LOT
        %    The value of this property must be an object of type
        %    mlreportgen.report.ReportLayout that allows you to override
        %    some properties of the LOT section's default layout such as
        %    its page orientation.
        %
        %    See also mlreportgen.report.ReporterLayout
        Layout;

        % LeaderPattern List of Tables (LOT) property 
        %    Specifies the leader pattern to be used in the 
        %    list of tables.
        %
        %    Valid values are:
        %
        %    Value               DESCRIPTION
        %    'dots' or '.'       leader of dots
        %    'space' or ' '      leader of spaces
        %
        %    Example
        %
        %    lot = mlreportgen.report.ListOfTables;
        %    lot.LeaderPattern = '.';
        %    lot.LeaderPattern = ' ';
        LeaderPattern;

        % Title List of Tables (LOT) section title
        %    Specifies the content of the LOT section title. You can use any
        %    of the following to specify the title content
        %
        %        - MATLAB string
        %        - character array
        %        - DOM object
        %        - 1xN or Nx1 array of strings or DOM objects
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          and/or DOM objects
        %        - ListOfTablesTitle reporter
        %
        %    Example
        %
        %    lot = mlreportgen.report.ListOfTables;
        %    lot.Title = mlreportgen.dom.Text('List of Tables');
        %    lot.Title.FontFamily = 'Helvetica';
        Title;

    end
end
