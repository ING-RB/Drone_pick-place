classdef ListOfCaptions< mlreportgen.report.Reporter
%mlreportgen.report.ListOfCaptions Create a List of Captions reporter
%    loc = ListOfCaptions() creates a reporter that generates a list of captions.
%    The captions are the contents of paragraphs that contain autonumbers 
%    with a specified stream name. The Report API provides reporters for 
%    creating lists of figures (mlreportgen.report.ListOfFigures) and lists 
%    of tables (mlreportgen.report.ListOfTables). You can use instances of 
%    this class to create lists of other types of objects in a report, for 
%    example, a list of equations or a list of authorities. To do this, 
%    your report program should append this object to the point in the report 
%    where you want the list to appear. The object should specify an autonumber 
%    stream name. Then, your program must create a paragraph in front of each 
%    item to be listed. The paragraph should specify a caption or title for 
%    the item and an autonumber having the specified name.
%    The appearance and behavior of the list of captions in the output report 
%    depends on the output type:
%
%      HTML- the list of captions is collapsible tree of hyperlinks to the 
%            captions in the report. It is located in the sidebar on the left 
%            hand side in the document. 
%
%      DOCX - If you open the report with rptview, the list of captions is 
%             genererated. If you open the report using Word directly, to 
%             generate the list of captions, you must update the Word document 
%             yourself. The list of captions is generated as a two-column table. 
%             The first column contains hyperlinks to the captions. The second 
%             column contains corresponding page numbers.
%
%      PDF - The list of captions is generated as part of the PDF document.
%
%    loc = ListOfCaptions(title) Creates a list of captions reporter that 
%    has the specified title.
%
%    loc = mlreportgen.report.ListOfCaptions(p1, v1, p2, v2,...) creates a
%    list of captions and sets its properties (p1, p2, ...) to the specified
%    values (v1, v2, ...).
%
%    ListOfCaptions properties:
%      Title                 - Title of list of captions section
%      AutoNumberStreamName  - Name of caption numbering stream
%      LeaderPattern         - Leader pattern for captions in list
%      Layout                - Page layout of list section
%      TemplateSrc           - Source of this reporter's template
%      TemplateName          - Template name in source template library
%      LinkTarget            - Hyperlink target for list of captions
%
%    ListOfCaptions methods:
%      getTitleReporter  - Get list of captions title reporter
%      getClassFolder    - Get location of folder that contains this class
%      createTemplate    - Copy the default list of captions template
%      customizeReporter - Subclasses ListOfCaptions for customization
%
%
%    Example
%
%     import mlreportgen.dom.*
%     import mlreportgen.report.*
% 
%     rpt = Report('Report with a List of Equation Captions', "pdf");
%     % rpt = Report('Report with a List of Equation Captions', "docx");
%     % rpt = Report('Report with a List of Equation Captions', "html");
%     % rpt = Report('Report with a List of Equation Captions', "html-file");
% 
%     loc = ListOfCaptions;
%     loc.AutoNumberStreamName = "equation";
%     append(rpt,loc);
% 
%     append(rpt, Chapter("Equations"));
% 
%     eq = Equation('e = m * c^2');
%     eq.DisplayInline = true;
%     append(rpt, eq);
% 
%     p = Paragraph('Equation ');
%     p.Style = {CounterInc('equation'),WhiteSpace('preserve')};
%     append(p,AutoNumber('equation'));
%     append(p, ' Mass–energy equivalence');
%     append(rpt,p);
% 
%     close(rpt);
%     rptview(rpt);
%    
%    See also rptview, mlreportgen.report.ListOfFigures, mlreportgen.report.ListOfTables, 
%    mlreportgen.report.Chapter, mlreportgen.report.Section, 
%    mlreportgen.dom.Heading, mlreportgen.dom.Paragraph

 
%   Copyright 2020-2023 The MathWorks, Inc.

    methods
        function out=ListOfCaptions
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.ListOfCaptions.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the
            %    ListOfCaptions template specified by type at the location
            %    specified by templatePath. You can use this method to
            %    create a copy of the default ListOfCaptions template to
            %    serve as a starting point for creating your own custom
            %    template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % path = mlreportgen.report.ListOfCaptions.customizeReporter(path)
            %    is a static method that creates a class definition file
            %    that defines a subclass of
            %    mlreportgen.report.ListOfCaptions
            %    class. You can use this file as a starting point for
            %    defining a custom ListOfCaptions class. The path argument is a
            %    string scalar or character vector that specifies the path 
            %    of the class definition file to be created.
            %
            %    Example
            %
            %    mlreportgen.report.ListOfCaptions.customizeReport("+myApp/@MyListOfCaptions")
            %    defines a ListOfCaptions subclass named myApp.MyListOfCaptions.
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = getClassFolder() return the folder location which contains this class.
        end

        function out=getTitleReporter(~) %#ok<STOUT>
            %getTitleReporter Gets the list of captions Title reporter
            % reporter = getTitleReporter(loc) returns the reporter that 
            % formats the title of the section generated by this ListofCaptions
            % reporter. ListOfCaptions reporter uses this reporter to format  
            % the content specified by the value of its Title property. You 
            % can use this reporter to customize the title alignment, position, 
            % and appearance.
            % See the mlreportgen.report.TitlePage help for information
            % on customizing reporter content. The help is specific to
            % title pages but applies to reporter content generally.
            %
            % See also mlreportgen.report.ListOfCaptions.Title,
            % mlreportgen.report.TitlePage
        end

    end
    properties
        % AutoNumberStreamName List Of Captions auto number stream name
        %    Name of the numbering stream, specified as a string scalar       
        %    or character vector 
        %
        %    Example
        %
        %    loc = mlreportgen.report.ListOfCaptions;
        %    loc.AutoNumberStreamName = "equation";
        AutoNumberStreamName;

        % Layout Page layout of this list of caption
        %    The value of this property must be an object of type
        %    mlreportgen.report.ReportLayout that allows you to override
        %    some properties of the list of caption section's default layout such as
        %    its page orientation.
        %
        %    See also mlreportgen.report.ReporterLayout
        Layout;

        % LeaderPattern List Of Captions leader pattern  
        %    Leader pattern between the caption and the page number, 
        %    specified as one of these values:
        %
        %    Value               DESCRIPTION
        %    'dots' or '.'       leader of dots
        %    'space' or ' '      leader of spaces
        %
        %    Example
        %
        %    loc = mlreportgen.report.ListOfCaptions;
        %    loc.LeaderPattern = '.';
        %    loc.LeaderPattern = ' ';
        LeaderPattern;

        % Title List Of Captions section title
        %    Specifies the content of the list of captions section title. 
        %    You can use any of the following to specify the title content
        %
        %        - string scalar
        %        - character array
        %        - DOM object
        %        - 1xN or Nx1 array of string scalars or DOM objects
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          and/or DOM objects
        %        - ListOfCaptionsTitle reporter
        %
        %    Example
        %
        %    loc = mlreportgen.report.ListOfCaptions;
        %    loc.Title = mlreportgen.dom.Text('List Of Captions');
        %    loc.Title.FontFamily = 'Helvetica';
        Title;

    end
end
