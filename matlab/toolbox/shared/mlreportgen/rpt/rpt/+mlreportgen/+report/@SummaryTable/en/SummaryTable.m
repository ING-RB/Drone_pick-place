classdef SummaryTable< mlreportgen.report.Reporter & mlreportgen.report.internal.SummaryTableBase
%mlreportgen.report.SummaryTable Reporter that summarizes results of MATLAB finders
%   reporter = SummaryTable() creates an empty SummaryTable reporter
%   object based on a default template. Use its properties to specify
%   finder results to summarize and what information to report for each
%   result. You must specify the result objects to be summarized.
%   Adding an empty SummaryTable reporter object to a report produces
%   an error.
%
%   reporter = SummaryTable(results) creates a SummaryTable reporter
%   for the finder result objects specified by the results argument.
%   The results argument must be a homogeneous array of objects having
%   base class mlreportgen.finder.Result. Result objects are returned
%   by the find method of finder classes in the mlreportgen.finder
%   package. Adding this reporter to a report, without any further
%   modification, adds tables summarizing the specified results based
%   on default settings. Use the reporter's properties to specify the
%   information to report for each result.
%
%   reporter = SummaryTable(p1=v1,p2=v2,...) creates a SummaryTable
%   reporter and initializes properties (p1, p2, ...) to the specified
%   values (v1, v2, ...).
%
%   SummaryTable properties:
%      FinderResults            - Array of result objects to be summarized
%      Title                    - Title of summary table
%      Properties               - Names of properties to be reported
%      IncludeLinks             - Whether to include links to details reporters
%      ShowEmptyColumns         - Whether to show table columns containing only empty values
%      TableReporter            - Table formatter for summary table
%      TemplateSrc              - Source of this reporter's template
%      TemplateName             - Name of this reporter's template
%
%    SummaryTable methods:
%      getClassFolder     - Get class definition folder
%      createTemplate     - Create copy of reporter template
%      customizeReporter  - Subclass this reporter
%      getImpl            - Get DOM implementation for this reporter
%      copy               - Create copy of this reporter and make deep copies of property values that reference a reporter, ReporterLayout, or DOM object
%
%     Example:
%
%         import mlreportgen.report.*
%         import mlreportgen.finder.*
%         
%         % Create a MATLAB Report
%         rpt = Report("MATLAB Summary Table Example","pdf");
%         
%         % Create a figure
%         f = figure;
%         
%         % Create two axes
%         axes1 = subplot(2,1,1);
%         x = linspace(0,10);
%         y1 = sin(x);
%         plot(x,y1);
%         axes1.Title = title('axes1');
%         
%         axes2 = subplot(2,1,2);
%         y2 = sin(5*x);
%         plot(x,y2);
%         axes2.Title = title('axes2');
%         
%         % Find axes in the figure using AxesFinder
%         result = find(AxesFinder(f));
%         
%         % Add results to Summary Table
%         summaryRptr = mlreportgen.report.SummaryTable(result);
%         
%         % Append the SummaryTable reporter to the report
%         append(rpt,summaryRptr);
%         
%         % Close the report and open the viewer
%         close(rpt);
%         rptview(rpt);
%
%     See also mlreportgen.finder.Result,
%     mlreportgen.finder.AxesFinder,
%     mlreportgen.finder.AxesResult

 
    %   Copyright 2021-2023 The MathWorks, Inc.

    methods
        function out=SummaryTable
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template =
            % mlreportgen.report.SummaryTable.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the
            %    SummaryTable reporter template specified by
            %    type at the location specified by templatePath. You can
            %    use this method to create a copy of a default
            %    SummaryTable reporter template to serve as a
            %    starting point for creating your own custom template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % classfile = mlreportgen.report.SummaryTable.customizeReporter(toClasspath)
            %    is a static method that creates an empty class derived from the
            %    SummaryTable reporter class with the name toClasspath. You can use the
            %    generated class as a starting point for creating your own custom
            %    version of the SummaryTable reporter.
            %
            %    For example:
            %    mlreportgen.report.SummaryTable.customizeReporter("path_folder/MySummaryTable.m")
            %    mlreportgen.report.SummaryTable.customizeReporter("+myApp/@SummaryTable")
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = mlreportgen.report.SummaryTable.getClassFolder()
            %    returns the folder location which contains this class.
        end

        function out=getImpl(~) %#ok<STOUT>
        end

    end
    properties
        % FinderResults Array of result objects to be summarized
        %   Array of result objects returned by a MATLAB finder. All
        %   result objects must be of the same class.
        FinderResults;

        % IncludeLinks Whether to include links to details reporters
        %   Whether to format the Title properties of each object as a link
        %   to the reporters that report more details about the objects. To
        %   access the details reporter for a result object, use the result
        %   object's getReporter method.
        %   Acceptable values are:
        %       - true  - (default) Format the Title property as a link to 
        %                 the reporter that corresponds to each object
        %       - false - Do not format the Title property as a link
        %
        % See also mlreportgen.finder.Result.getReporter
        IncludeLinks;

        % Properties Names of properties to be reported
        %   List of properties to be reported for each object in the
        %   summary table, specified as an array of strings or a cell array
        %   of character vectors. In the summary table, one table column is
        %   created for each property. If this property is empty (default),
        %   the reporter automatically determines which properties to
        %   report using the specified results' getDefaultSummaryProperties
        %   methods. For information on which properties are supported for
        %   a specific result class, see that class's getPropertyValues
        %   method.
        %
        % See also mlreportgen.finder.Result.getDefaultSummaryProperties,
        % mlreportgen.finder.Result.getPropertyValues
        Properties;

        % ShowEmptyColumns Whether to show table columns containing only empty values
        %   Whether to include columns in the summary table that do not
        %   have any data. Acceptable values are:
        %       - false - (default) Do not include empty columns in the 
        %                 summary table
        %       - true  -  Include empty columns in the summary table
        ShowEmptyColumns;

        % TableReporter Table formatter for summary table
        %   Specifies an mlreportgen.report.BaseTable object to be used to
        %   format the summary table. The default value of this property is
        %   an empty BaseTable object with StyleName set to
        %   "SummaryTableTable". You can customize the appearance of
        %   the content by modifying the properties of the default object
        %   or by replacing it with another BaseTable object. Any content
        %   added to the title in this property appears before the
        %   content specified in the Title property of this reporter.
        %
        %   See also mlreportgen.report.BaseTable
        TableReporter;

        % Title Title of summary table
        %   Title used for the summary table, specified as a string,
        %   character vector, or DOM object. The contents of this property
        %   is reported with each summary table included by the reporter.
        %   If this property is empty (default), the reporter automatically
        %   creates a table title using the specified result class's
        %   getDefaultSummaryTableTitle method.
        %
        % See also mlreportgen.finder.Result.getDefaultSummaryTableTitle
        Title;

    end
end
