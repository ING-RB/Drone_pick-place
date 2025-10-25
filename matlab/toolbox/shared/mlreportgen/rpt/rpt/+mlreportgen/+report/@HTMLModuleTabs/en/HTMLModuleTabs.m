classdef HTMLModuleTabs< mlreportgen.report.Reporter
%mlreportgen.report.HTMLModuleTabs Create an HTML module tabs container
%   reporter = HTMLModuleTabs() creates an empty HTMLModuleTabs
%   reporter to include a module tabs container in an HTML report.
%   Module tabs container groups related content into a set of
%   user-selectable panes, only one of which is visible in the report
%   at any given time. Use the reporter's TabsData property to specify
%   the label and the content for the tabs. You must specify the data
%   for the tabs to be reported. Adding an empty HTMLModuleTabs
%   reporter object to a report produces an error.
%
%   reporter = HTMLModuleTabs('p1', 'v1', 'p2', 'v2', ...) creates an
%   HTMLModuleTabs reporter and sets its properties (p1, p2, ...) to
%   the specified values (v1, v2, ...).
%
%   Note: You can use this reporter only with the reports of type
%   "HTML" and "HTML-FILE". Adding this reporter to a "DOCX" or "PDF"
%   report produces an error.
%
%   HTMLModuleTabs properties:
%     TabsData              - Tabs Data
%     TemplateSrc           - Source of this reporter's template
%     TemplateName          - Name of this reporter's template
%     LinkTarget            - Hyperlink target for this reporter's content
%
%   HTMLModuleTabs methods:
%     getClassFolder        - Get location of folder that contains this class
%     createTemplate        - Copy the default HTMLModuleTabs template
%     customizeReporter     - Subclasses HTMLModuleTabs for customization
%     getImpl               - Get DOM implementation for this reporter
%
%   Example 1:
%       % Example to report on all the system diagrams in a Simulink
%       % model as a tabbed image gallery.
%
%       % Create a Simulink report
%       rpt = slreportgen.report.Report("MyReport","html-file");
%       open(rpt);
%
%       % Create a chapter
%       chap = mlreportgen.report.Chapter("sf_car system diagrams tabbed image gallery");
%
%       % Load the model
%       model_name = "sf_car";
%       load_system(model_name);
%
%       % Find all the diagrams in the model
%       finder = slreportgen.finder.DiagramFinder(model_name);
%       results = find(finder);
%
%       % Create a HTMLModuleTabs reporter and specify the tabs data
%       moduleTabs = mlreportgen.report.HTMLModuleTabs();
%       for result = results
%           % Specify the tab label as the system name
%           moduleTabs.TabsData(end+1).Label = result.Name;
%
%           % Specify the tab content as the system diagram snapshot
%           diag = result.getReporter();
%           moduleTabs.TabsData(end).Content = mlreportgen.dom.Image(diag.getSnapshotImage(rpt));
%       end
%
%       % Add the reporter to the chapter and chapter to the report
%       add(chap,moduleTabs);
%       add(rpt,chap);
%
%       % Close and view the report
%       close(rpt);
%       rptview(rpt);
%
%
%   Example 2:
%       % Example to report on content of multiple types, like text,
%       % link, table, image, etc., using a module tab container.
%
%       % Create a report
%       rpt = mlreportgen.report.Report("MyReport","html");
%       open(rpt);
%
%       % Create a chapter
%       chap = mlreportgen.report.Chapter("HTMLModuleTabs reporter example");
%
%       % Create a HTMLModuleTabs reporter and specify label and
%       % content for each tab
%       moduleTabs = mlreportgen.report.HTMLModuleTabs();
%       moduleTabs.TabsData(1).Label = "Text";
%       moduleTabs.TabsData(1).Content = "This tab contains text as string.";
%
%       moduleTabs.TabsData(2).Label = "Paragraph";
%       moduleTabs.TabsData(2).Content = ...
%           mlreportgen.dom.Paragraph("This tab contains content using a DOM Paragraph.");
%
%       moduleTabs.TabsData(3).Label = "Link";
%       moduleTabs.TabsData(3).Content = ...
%           mlreportgen.dom.ExternalLink("http://www.mathworks.com/","MathWorks");
%
%       moduleTabs.TabsData(4).Label = "List";
%       moduleTabs.TabsData(4).Content = ...
%           mlreportgen.dom.UnorderedList({"Coffee", "Tea", "Milk"});
%
%       moduleTabs.TabsData(5).Label = "Table";
%       moduleTabs.TabsData(5).Content = ...
%           mlreportgen.dom.Table(magic(2));
%
%       moduleTabs.TabsData(6).Label = "Image";
%       moduleTabs.TabsData(6).Content = ...
%           mlreportgen.dom.Image(which("ngc6543a.jpg"));
%
%       % Add the reporter to the chapter and chapter to the report
%       add(chap,moduleTabs);
%       add(rpt,chap);
%
%       % Close and view the report
%       close(rpt);
%       rptview(rpt);

     
    % Copyright 2019-2023 The MathWorks, Inc.

    methods
        function out=HTMLModuleTabs
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template =
            % mlreportgen.report.HTMLModuleTabs.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the
            %    HTMLModuleTabs reporter template specified by type at the
            %    location specified by templatePath. You can use this
            %    method to create a copy of a default HTMLModuleTabs
            %    reporter template to serve as a starting point for
            %    creating your own custom template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % classfile = mlreportgen.report.HTMLModuleTabs.customizeReporter(toClasspath)
            %    is a static method that creates an empty class derived
            %    from the HTMLModuleTabs reporter class with the name
            %    toClasspath. You can use the generated class as a starting
            %    point for creating your own custom version of the
            %    HTMLModuleTabs reporter.
            %
            %    For example:
            %    mlreportgen.report.HTMLModuleTabs.customizeReporter("path_folder/MyHTMLModuleTabs.m")
            %    mlreportgen.report.HTMLModuleTabs.customizeReporter("+myApp/@HTMLModuleTabs")
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = mlreportgen.report.HTMLModuleTabs.getClassFolder()
            %    is a static method that returns the path of the folder
            %    that contains the definition of this class.
        end

        function out=getImpl(~) %#ok<STOUT>
        end

    end
    properties
        % TabsData Tabs Data
        %    Specifies the tabs data that includes the tab label and the
        %    tab content for each tab. TabsData is specified as an array
        %    of struct, with the struct having the following fields:
        %       - Label: Specifies the tab label as a string scalar, a
        %         character vector, or a DOM Text object. The label should
        %         be unique for each tab that depicts the corresponding
        %         tab content.
        %       - Content: Specifies the tab content as one of following
        %         values:
        %             - String scalar or character vector
        %             - DOM object
        %             - Report API reporter object
        TabsData;

    end
end
