classdef BaseTable< mlreportgen.report.Reporter
%mlreportgen.report.BaseTable Create a table-with-title reporter
%    rptr = BaseTable() creates an empty table reporter. You
%    can use its properties to specify a table and an automatically
%    numbered table title. The default style for the table is a grid.
%    You can use the reporter's TableStyleName property to specify a
%    custom table style.
%
%    rptr = BaseTable(content) Creates a reporter that formats content
%    as a table and adds it to a report.
%
%    rptr = BaseTable('p1', v1, 'p2', v2,...) creates a table reporter
%    and sets its properties (p1, p2, ...) to the specified values (v1,
%    v2, ...).
%
%    BaseTable properties:
%      Title                     - Table title
%      Content                   - Table content
%      TableStyleName            - Name of style used to format this table
%      TableWidth                - Width of table
%      MaxCols                   - Maximum table columns to display per table slice
%      RepeatCols                - Number of initial columns to repeat per slice
%      TableSliceTitleStyleName  - Name of style used to format the table slices title
%      TableEntryUpdateFcn       - Function to update table entries
%      TemplateSrc               - Table reporter's template source
%      TemplateName              - Template name
%      LinkTarget                - Hyperlink target for this table
%
%    BaseTable methods:
%      getTitleReporter   - Get BaseTable caption reporter
%      getContentReporter - Get BaseTable content reporter
%      getClassFolder     - Get location of folder that contains this class
%      createTemplate     - Create a custom BaseTable reporter template
%      customizeReporter  - Subclasses BaseTable for customization
%      getImpl            - Get DOM implementation for this reporter
%
%    Example
%
%    import mlreportgen.report.*
%    import mlreportgen.dom.*
%    report = Report("tables");
%    chapter = Chapter();
%    chapter.Title = "Table example";
%    append(report,chapter);
%    table = BaseTable(magic(5));
%    table.Title = "Rank 5 Magic Square";
%    append(report,table);
%    append(report,Paragraph());
%    imgSize = {Height("2in"), Width("2in")};
%    img1 = Image(which("b747.jpg"));
%    img1.Style = imgSize;
%    img2 = Image(which("peppers.png"));
%    img2.Style = imgSize;
%    table = BaseTable({"Boeing 747", "Peppers"; img1, img2});
%    table.Title = "Picture Gallery";
%    append(report,table);
%    close(report);
%    rptview(report);

 
    %   Copyright 2017-2023 The MathWorks, Inc.

    methods
        function out=BaseTable
        end

        function out=appendTitle(~) %#ok<STOUT>
            % Updates the title of this BaseTable reporter, so that the
            % title specified in the Title property of this reporter appear
            % before the new title specified by the newTitle
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.BaseTable.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the BaseTable
            %    template specified by type at the location specified by
            %    templatePath. You can use this method to create a copy of
            %    a default BaseTable template to serve as a starting
            %    point for creating your own custom template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % classfile = mlreportgen.report.BaseTable.customizeReporter(toClasspath)
            %    is a static method that creates a class definition file
            %    that defines a subclass of mlreportgen.report.BaseTable
            %    class. You can use this file as a starting point for
            %    defining a custom base table class. The toClasspath
            %    argument is a string that specifies the path of the class
            %    definition file to be created.
            %
            %    Example
            %    mlreportgen.report.BaseTable.customizeReporter("path_folder/MyBaseTable.m")
            %    mlreportgen.report.BaseTable.customizeReporter("+myApp/@BaseTable")
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = getClassFolder() return the folder location which contains this class.
        end

        function out=getContentReporter(~) %#ok<STOUT>
            % mlreportgen.report.BaseTable.getContentReporter
            % reporter = getContentReporter(baseTable) returns a hole
            % reporter that the base table reporter uses to insert its
            % content into a report. The default template, named
            % BaseTableContent, resides in the BaseTable reporter's
            % template library. It contains only a hole for the table
            % generated from the base reporter's Content property. This
            % method allows you to use a customized version of the Content
            % template to add a table to a report. For example, suppose
            % that you have created a customized version of the template
            % and stored it in your report's main template library under
            % the name BaseTableContent. Then you could use the following
            % script to apply the custom template:
            %
            % Example
            %
            % import mlreportgen.report.*
            % import mlreportgen.dom.*
            % rpt = Report('myreport', 'pdf', 'myreporttemplate');
            % tableRptr = BaseTemplate;
            % tableContentRptr = getContentReporter(tableRptr);
            % tableContentRptr.TemplateSrc = rpt;
            % tableContentRptr.Content = Table(magic(5));
            % tableRptr.Content = tableContentRptr;
            % add(rpt, tableRptr);
            % close(rpt);
            %
            % See also mlreportgen.report.BaseTable.Content
        end

        function out=getImpl(~) %#ok<STOUT>
        end

        function out=getTitleReporter(~) %#ok<STOUT>
            % mlreportgen.report.BaseTable.getTitleReporter
            % rptr = getTitleReporter(table) returns a reporter that the
            % table reporter uses to format the content specified by
            % the value of its Title property. You can use this reporter to
            % customize the title alignment, position, and appearance. See
            % the TitlePage help for an example of how to use a title
            % reporter to customize a title.
            %
            % See also mlreportgen.report.BaseTable.Title,
            % mlreportgen.report.TitlePage
        end

        function out=getTranslations(~) %#ok<STOUT>
            % translations = getTranslations() returns a persintent map with this reporter
            %     translations
        end

    end
    properties
        %Content Content of table to be reported
        %    Valid values are
        %      - DOM Table
        %      - DOM Formal Table
        %      - DOM MATLAB Table
        %      - builtin MATLAB table array
        %      - A two-dimensional array or cell array of DOM or builtin
        %        MATLAB objects
        %      - Hole reporter returned by getContentReporter
        %
        %    See also mlreportgen.dom.Table, mlreportgen.dom.FormalTable,
        %    mlreportgen.dom.MATLABTable
        Content;

        %MaxCols  Maximum table columns to display per table slice
        %   Specifies the maximum number of table columns per table slice that
        %   BaseTable uses to slice the input DOM/Formal table. If the actual number
        %   of columns of the original data is greater than the value of
        %   this property, the data is sliced vertically (column wise) into
        %   multiple slices and generated as multiple tables. The default
        %   value of this property is Inf, which generates a single table
        %   regardless of the data array size. This may result in some tables
        %   being illegible, depending on the size of the data being displayed.
        %   To avoid creation of illegible tables, change the default setting
        %   of the property to a value small enough to fit legibly on a page.
        %   You may have to experiment to determine the optimum values of
        %   the maximum column size. Each slice has a title that specifies
        %   the column range of the slice.
        MaxCols;

        %RepeatCols  Number of initial columns to repeat per slice
        %   Specifies the number of initial columns to repeat per table slice.
        %   A value of n repeats the first n columns of the original table
        %   in each slice. 
        %   For example, RepeatCols=2 repeats the first two columns of the
        %   original table in each slice. The default value of this property is 0,
        %   which specifies no repeating columns. 
        %   The reporter's MaxCols property includes the RepeatCols property.
        %   For example, RepeatCols=2 and MaxCols=4 generates 4-column slices
        %   with the first two columns repeating the first two columns of the original table.
        RepeatCols;

        %TableEntryUpdateFcn Function to update a table entry
        %    Handle of a function to update an entry of the base table. 
        %    This function is called for each entry in the base table.
        %    It should accept an input argument of type mlreportgen.dom.TableEntry.
        %
        %    Example:
        %
        %         % Function handle to format background color of table entry objects
        %         function updateTableEntry(entry)
        %             import mlreportgen.dom.*
        %             entryContent = entry.Children(1);
        %             if isa(entryContent,'mlreportgen.dom.Text')
        %                 entryContent = entryContent.Content;
        %                 if strcmp(entryContent,'N/A')
        %                     entry.Style = [entry.Style,{BackgroundColor('red')}];
        %                 end
        %             end
        %         end
        % 
        %         myReporter.TableEntryUpdateFcn = @updateTableEntry;
        TableEntryUpdateFcn;

        %TableSliceTitleStyleName Name of the style applied to the table
        %slice titles
        %    The value of this property may be a string or a character
        %    array that specifies a custom style to be applied to the title
        %    of table slices generated by this reporter. The specified
        %    style must be defined in the report to which this reporter is
        %    added. If the property is empty, a style defined in this
        %    reporter's template is applied to the slice titles.
        TableSliceTitleStyleName;

        %TableStyleName Name of style to be applied to the reported table
        %    The value of this property may be a string or a character
        %    array that specifies a table style defined in the template
        %    used by the report you append this table to or in the template
        %    of a reporter added to the report. An empty value specifies a
        %    default table style defined in this reporter's template.
        TableStyleName;

        %TableWidth Width applied to the Table.
        %     The value of this property must be a string or a character
        %     array having the format valueUnits where Units is an
        %     abbreviation for the units in which the size is expressed.
        %     The following abbreviations are valid:
        %
        %           Abbreviation  Units
        %
        %           px            pixels
        %           cm            centimeters
        %           in            inches
        %           mm            millimeters
        %           pc            picas
        %           pt            points
        %           %             percent
        TableWidth;

        %Title  Title of table to be reported
        %    Specifies the text of the table title. The value of this
        %    property may be a
        %        - MATLAB string
        %        - character array
        %        - DOM object
        %        - 1xN or Nx1 array of strings or DOM objects
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          and/or DOM objects
        %        - Hole reporter returned by getTitleReporter
        %
        %    If the value of this property is inline content, i.e., content
        %    that can fit in a paragraph, the reporter uses a template
        %    stored in its template library to format the title. The
        %    template automatically numbers the title as follows. If the
        %    table is in a numbered chapter, a string of the form 'Table
        %    N.M. ' prefixes the title text, where where N is the number
        %    of the chapter and M is the number of the table in the
        %    chapter. For example, the prefix for the third table in the
        %    second chapter of the report is Table 2.3. A prefix of the
        %    form 'Table N. ' precedes the title text in unnumbered
        %    chapters, where N is 1 for the first table in the report, 2
        %    for the second table, etc. In many non-English locales, the
        %    title prefix is translated to the language and format of the
        %    locale. See mlreportgen.report.Report.Locale for a list of
        %    translated locales.
        Title;

    end
end
