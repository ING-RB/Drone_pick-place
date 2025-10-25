classdef Chapter< mlreportgen.report.Section
%mlreportgen.report.Chapter Create a chapter reporter
%    chapter = Chapter() creates a chapter reporter that generates a
%    section with a new page layout defined by the reporter's default
%    template. The default template defines a portrait page layout with
%    a header and a footer. The header is empty. The footer contains an
%    automatically generated page number that starts with 1 if this is
%    the first chapter to be added to a report or continues from the last
%    page of the previous chapter. You can use the chapter's Layout
%    property to override some of the chapter's page layout features, such
%    as its orientation. Use the chapter's add method to add content to the
%    chapter.
%
%    chapter = Chapter(title) creates a chapter with a title. The title
%    appears at the beginning of the chapter, in the report's table of
%    contents, and in the header of all but the first page of the chapter.
%    The title is numbered by default. You can use the chapter's Numbered
%    property to turn off numbering for this chapter. You can use the
%    mlreportgen.report.Section.number method to turn off numbering for
%    this and all other chapters in the report. If numbered, the title is
%    prefixed in English reports by a string of the form Chapter N., where
%    N is the automatically generated chapter number. In some other
%    locales, the English prefix is translated to the language of the
%    locale. See mlreportgen.report.Report.Locale for a list of translated
%    locales.
%
%    Note: For the page headers to correctly display the title, the
%    style name of the title must be "SectionTitle1". If the title is
%    specified as a DOM Paragraph object with no StyleName set, the
%    StyleName property is automatically changed to the correct style
%    name. You can customize the paragraph style by including DOM style
%    objects in the Style property. If you use a custom template to
%    format the title, make sure the style name used by the template is
%    "SectionTitle1". Customize the title style by modifying the
%    "SectionTitle1" style in the custom template.
%
%    chapter = Chapter(p1, v1, p2, v2,...) creates a chapter and sets
%    its properties (p1, p2, ...) to the specified values
%    (v1, v2, ...).
%
%    Chapter properties:
%      Title             - Chapter title
%      Numbered          - Whether to number this chapter
%      Content           - DOM objects and reporters that chapter contains
%      TemplateSrc       - Chapter reporter's template source
%      TemplateName      - Chapter reporter's template name
%      LinkTarget        - Hyperlink target for chapter
%      Layout            - Page layout of this chapter
%
%    Chapter methods:
%      append            - Add DOM objects and reporters to this chapter
%      add               - Alias for append
%      getTitleReporter  - Get chapter title reporter
%      number            - Whether to number all chapters in a report
%      createTemplate    - Copy one of the default Chapter templates
%      customizeReporter - Subclasses Chapter for customization
%      getImpl           - Get DOM implementation for this reporter
%      getClassFolder    - Get class definition folder
%
%    See also mlreportgen.report.Report.Locale

     
    %    Copyright 2017-2023 Mathworks, Inc.

    methods
        function out=Chapter
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % classfile = mlreportgen.report.Chapter.customizeReporter(toClasspath)
            %    is a static method that creates an empty class derived from the
            %    Chapter reporter class with the name toClasspath. You can use the
            %    generated class as a starting point for creating your own custom
            %    version of the Chapter reporter.
            %
            %    For example:
            %    mlreportgen.report.Chapter.customizeReporter("path_folder/MyChapter.m")
            %    mlreportgen.report.Chapter.customizeReporter("+myApp/@Chapter")
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = mlreportgen.report.Chapter.getClassFolder() returns
            % the path of the folder that contains the class definition
            % file for this class.
        end

        function out=getTitleReporter(~) %#ok<STOUT>
            % getTitleReporter Creates a section title reporter
            %    rptr = getTitleReporter(chapter) creates a SectionTitle
            %    reporter partially configured to format the Chapter
            %    reporter's Title property and fill the Title hole in the
            %    Chapter reporter's template with the formatted title. The
            %    value of the Title property must be a character array,
            %    string, or inline DOM object. Otherwise, this method
            %    triggers an error.
            %
            %    The SectionTitle reporter getImpl method uses this method
            %    to format inline title content. You can use this method to
            %    customize inline chapter title format as follows:
            %
            %    1. Invoke this method to get a default SectionTitle 
            %       reporter.
            %    2. Customize the reporter's properties, for example,
            %       specify a template source containing customized title
            %       templates. See Default SectionTitle Properties below.
            %    3. Set the Chapter reporter's Title property to the
            %       customized SectionTitle reporter.
            %
            %    Example:
            %
            %    import mlreportgen.report.*
            %
            %    rpt = Report("myrpt", 'pdf');
            %
            %    ch = Chapter("Title", "Introduction");
            %    titleRptr = getTitleReporter(ch);
            %    % MyCustomTemplate contains customized version of standard
            %    % template SectionNumberedTitle1.
            %    titleRptr.TemplateSrc = "MyCustomTemplate.pdftx';
            %    ch.Title = titleRptr;
            %    append(rpt, ch);
            %    close(rpt);
            % 
            %    Default SectionTitle Properties
            %
            %    You can customize the title format by changing the default
            %    values for the following properties:
            %
            %    TemplateSrc
            %
            %    Set by default to Chapter reporter template. Note that the
            %    Chapter reporter uses the Section reporter template by
            %    default. This template's template library contains default
            %    section title templates named SectionTitle1,
            %    SectionTitle2, etc., for unnumbered titles and
            %    SectionNumberedTitle1, SectionNumberedTitle2, etc., for
            %    hierarchically numbered titles. The Chapter reporter uses
            %    only the SectionNumberedTitle1 and the SectionTitle1
            %    templates. You can set this property to the source of a
            %    template file that contains custom definitions of these
            %    templates.
            %
            %    TemplateName
            %
            %    Set by default to SectionNumberedTitle if the Chapter
            %    reporter's Numbered property is true (the default);
            %    otherwise, to SectionTitle. You do not need to change this
            %    setting if your custom template library customizes the
            %    definitions of the standard title templates but not their
            %    names, for example, if your template library contains a
            %    template named SectionNumberedTitle1 with a customized
            %    version of the standard definition for
            %    SectionNumberedTitle1.
            %
            %    OutlineLevel
            %
            %    Set to 1 by default. Do not change this setting.     
            %
            %    Content
            %
            %    Set by default to the value of the Chapter reporter Title
            %    property.
            %
            %    NumberPrefix
            %
            %    Set by default to []. Do not change this setting.
            %
            %    NumberSuffix
            %
            %    Set to ". " if the Section Numbered property is true (the
            %    default; otherwise, to []. Do not change this setting.
            %
            %    HoleId
            %
            %    Set to Title by default. Do not change this setting.
            %
            %    Translations
            %
            %    Set by default to translations for the NumberPrefix and
            %    NumberSuffix property. The translations for NumberPrefix
            %    are translations of the English noun Chapter. The
            %    translations include translations of Chapter for most
            %    European and East Asian locales. You can add missing
            %    locales by setting this property. See the help for the
            %    Translations property for more information.
            %
            %    See also mlreportgen.report.Chapter.Title, 
            %    mlreportgen.report.SectionTitle
        end

        function out=getTranslations(~) %#ok<STOUT>
            % translations = getTranslations() returns a persintent map with this reporter
            %     translations
        end

        function out=number(~) %#ok<STOUT>
            % number(rpt, value) specifies whether to number report chapters.
            %    A value of true causes the Report API to number all
            %    chapters in a report. You can override this global
            %    numbering setting for individual chapters, using the
            %    chapter Numbered property.
            %
            %    See also mlreportgen.report.Chapter.Numbered
        end

    end
    properties
        % Layout Page layout of this chapter
        % The value of this property is an object of type
        % mlreportgen.report.ReporterLayout that allows you to
        % override some of the page layout properties, such as page
        % orientation, defined by the chapter's template.
        %
        %  Note: the Chapter object initializes this property to a layout
        %  object. You cannot subsequently set this property. However,
        %  you can set the initial layout object's properties.
        %
        %  Note: The default first page number of chapter layouts is [],
        %  which continues numbering from the previous chapter. The Report
        %  API overrides the default for the first chapter in a report,
        %  setting its first page number to 1. This is to implement a
        %  common page numbering scheme where the first chapter in a
        %  document starts on page 1 and page numbers continue in
        %  succeeding chapter. You can use the chapter layout to override
        %  this behavior. For example, to continue first chapter page
        %  numbering from the report TOC, set the FirstPageNumber to -1.
        %
        %  Example
        %
        %  import mlreportgen.report.*
        %  rpt = Report('myreport', 'docx');
        %  append(rpt, TitlePage('Title', 'My Report'));
        %  append(rpt, TableOfContents);
        %  ch = Chapter('Title', 'Information');
        %  ch.Layout.FirstPageNumber = -1;
        %  append(rpt, ch);
        %  append(rpt, Chapter('Title', 'More Information'));
        %  close(rpt);
        %  rptview(rpt);
        %
        %  See also mlreportgen.report.ReporterLayout,
        %  mlreportgen.report.Layout.FirstPageNumber
        Layout;

    end
end
