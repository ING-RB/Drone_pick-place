classdef Report< mlreportgen.report.ReportBase & mlreportgen.report.internal.Report
%REPORT  Container for a report based on reporters and MATLAB and DOM objects
%    report = mlreportgen.report.Report() creates a report object with
%    a default report type (pdf) and file path ("untitled.pdf").
%
%    report = mlreportgen.report.Report(path) creates a report object 
%    with the default report type (pdf) and the specified output path.
%
%    report = mlreportgen.report.Report(path, type) creates a report object 
%    with the specified report type and output path. Valid file types are
%
%        'pdf'        - PDF report
%        'pdfa'       - PDF Archival report
%        'docx'       - Microsoft Word report
%        'html'       - multifile HTML report packaged as an htmx (zip) file
%        'html-file'  - single-file HTML report
% 
%    report = mlreportgen.report.Report(path, type, template) creates a
%    report object with the specified report type, output path, and 
%    template. The template argument is a string or character array that
%    specifies the path of a template to be used to format the report.
%    The template type must be of the same type as the report, i.e., an
%    HTML template for an HTML report.
%    
%    report = mlreportgen.report.Report(p1, v1, p2, v2,...) creates a
%    report and sets its properties (p1, p2, ...) to the specified values
%    (v1, v2, ...).
%
%    Report properties:
%      OutputPath      - Path of the generated report file
%      PackageType     - How to package document output
%      Type            - Type of the generated report, e.g., PDF or DOCX
%      Layout          - Page layout of the report contents
%      Locale          - Locale for which the report is to be generated
%      TemplatePath    - Path of the template used to format this report
%      Document        - DOM implementation of this report
%      Context         - Report context
%      Debug           - Puts report in debug mode
%
%    Report methods:
%      open                   - Open the report
%      append                 - Add content to the report
%      add                    - Alias for append
%      close                  - Close and generate the report
%      rptview                - Open the generated report file in a viewer
%      createTemplate         - Copy the default report template
%      customizeReport        - Subclasses Report for customization
%      getClassFolder         - Get class definition folder
%      getTempPath            - Get path of report temporary directory
%      generateFileName       - Generate a temporary file name
%      getReportLayout        - Get current report layout
%      fill                   - Fill holes in this report's template
%      getContext             - Get a report context item
%      setContext             - Set a report context item
%      ispdf                  - Check if this is a PDF report
%      isdocx                 - Check if this is a Word report
%      ishtml                 - Check if this is a multifile HTML report
%      ishtmlfile             - Check if this is a single-file HTML report
%
%    Example
%
%    import mlreportgen.report.*
%    import mlreportgen.dom.*
%    rpt = Report('My Report', 'pdf');
%    append(rpt, TitlePage('Title', 'My Report'));
%    append(rpt, TableOfContents);
%    ch = Chapter('Images');
%    append(ch, Section('Title',  'Boeing 747', ...
%        'Content', Image(which('b747.jpg'))));
%    append(ch, Section('Title',  'Peppers', ...
%        'Content', Image(which('peppers.png'))));
%    append(rpt, ch);
%    close(rpt);
%    rptview(rpt);
%
%    Report Page Numbering
%
%    The Report API uses the following scheme to number the pages of
%    report sections:
%
%        Reporter            First Page Number of Section
%        ------------------  ------------------------------------------
%        TitlePage           Starts at 1 (page number does not appear)       
%        TableOfContents     Restarts numbering at i
%        First Chapter       Restarts numbering at 1
%        Following Chapters  Continue from previous chapter
%        
%    You can use reporter Layout properties to override this numbering
%    scheme. 
%
%    See also mlreportgen.report.Layout.FirstPageNumber,
%    mlreportgen.report.TitlePage.Layout,
%    mlreportgen.report.TableOfContents.Layout,
%    mlreportgen.report.Chapter.Layout

 
%    Copyright 2017-2023 Mathworks, Inc.

    methods
        function out=Report
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.Report.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the report
            %    template specified by type at the location specified by
            %    templatePath. You can use this method to create a copy of
            %    a default Report template to serve as a starting point for
            %    creating your own custom template.
        end

        function out=customizeReport(~) %#ok<STOUT>
            % path = mlreportgen.report.Report.customizeReport(path)
            %    is a static method that creates a class definition file
            %    that defines a subclass of mlreportgen.report.Report
            %    class. You can use this file as a starting point for
            %    defining a custom report class. The path argument is a
            %    string that specifies the path of the class definition
            %    file to be created.
            %
            %    Example
            %
            %    mlreportgen.report.Report.customizeReport("+myApp/@Report")
            %
            %    defines a Report subclass named myApp.Report
        end

        function out=getClassFolder(~) %#ok<STOUT>
            %mlreportgen.report.Report.getClassFolder
            % path = getClassFolder() is a static method that returns the
            % path of the folder that contains the class definition file
            % for an mlreportgen.report.Report object.
        end

    end
end
