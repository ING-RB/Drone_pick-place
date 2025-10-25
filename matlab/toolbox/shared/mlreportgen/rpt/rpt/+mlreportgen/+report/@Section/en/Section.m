classdef Section< mlreportgen.report.Reporter
%mlreportgen.report.Section Create a report section reporter
%    section = Section() creates a reporter that generates a report
%    section. You can add the reporter to a report, to a chapter, or
%    another section. If added to a report, the section reporter starts the
%    section on a new, portrait page with default margins and a page number
%    in the footer. The page number equals the previous page number plus
%    one. If added to a chapter or another section, the section reporter
%    creates a sub section that continues on the current page.
%
%    section = Section(title) creates a report section containing a
%    section title with the specified title text. A hierarchical section
%    number prefixes the title text by default. For example, the number of
%    the first subsection in the second chapter is 2.1. The size of the
%    title diminishes by default with the depth of the section in the
%    report hierarchy up to five levels deep. 
%
%    section = Section('p1', v1, 'p2', v2,...) creates a section and sets
%    its properties (p1, p2, ...) to the specified values (v1,
%    v2, ...).
%
%    Section properties:
%      Title             - Section title
%      Numbered          - Whether to number this section
%      Content           - DOM objects and reporters that section contains
%      TemplateSrc       - Section reporter's template source
%      TemplateName      - Section reporter's template name
%      LinkTarget        - Hyperlink target for section
%
%    Section methods:
%      append            - Append DOM and reporter objects to the section
%      add               - Alias for append
%      getTitleReporter  - Get section title reporter
%      number            - Whether to number all sections in a report
%      createTemplate    - Copy the default section template
%      customizeReporter - Subclasses Section for customization
%      getClassFolder    - Get class definition folder
%      getImpl           - Get DOM implementation for this reporter
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
%    See also mlreportgen.report.Chapter, mlreportgen.report.Section.number

 
%   Copyright 2017-2023 The MathWorks, Inc.

    methods
        function out=Section
        end

        function out=add(~) %#ok<STOUT>
            %add Add content to a Sectopm object.
            %    This method is an alias for the append method. It
            %    performs the same function as the append method.
            %    You can use either method to append content to
            %    Report objects.
            %
            %    Note: you must use append to add content to DOM API
            %    objects, such as mlreportgen.dom.Paragraph.
            %
            %    See also mlreportgen.report.Section.append
        end

        function out=append(~) %#ok<STOUT>
            % append(section, content) Add content to this section. Content
            % can include most builtin MATLAB objects,  DOM objects,
            % Report API reporters, and object and cell arrays of objects
            % that can be added individually to a section.
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.Section.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the Section
            %    template specified by type at the location specified by
            %    templatePath. You can use this method to create a copy of
            %    a default Section template to serve as a starting
            %    point for creating your own custom template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % path = mlreportgen.report.Section.customizeReporter(path)
            %    is a static method that creates a class definition file
            %    that defines a subclass of mlreportgen.report.Section
            %    class. You can use this file as a starting point for
            %    defining a custom section class. The path argument is a
            %    string that specifies the path of the class definition
            %    file to be created.
            %
            %    Example
            %
            %    mlreportgen.report.Section.customizeReporter("+myApp/@MySection")
            %
            %    defines a Section subclass named myApp.MyTitlePage.
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = getClassFolder() return the folder location which contains this class.
        end

        function out=getImpl(~) %#ok<STOUT>
            %    impl = getImpl(section, rpt) Return a DOM implementation object capable
            %           of being added to a document specified by report
        end

        function out=getTitleReporter(~) %#ok<STOUT>
            % getTitleReporter Creates a section title reporter
            %    rptr = getTitleReporter(section) creates a SectionTitle
            %    reporter partially configured to format the Section
            %    reporter's Title property and fill the Title hole in the
            %    Section reporter's template with the formatted title. The
            %    value of the Title property must be a character array,
            %    string, or inline DOM object. Otherwise, this method
            %    triggers an error.
            %
            %    The SectionTitle reporter getImpl method uses this method
            %    to format inline title content. You can use this method to
            %    customize inline title format as follows:
            %
            %    1. Invoke this method to get a default SectionTitle 
            %       reporter.
            %    2. Customize the reporter's properties, for example,
            %       specify a template source containing customized title
            %       templates. See Default SectionTitle Properties below.
            %    3. Set the Section reporter's Title property to the
            %       customized SectionTitle reporter.
            %
            %    Example
            %
            %    import mlreportgen.report.*
            %
            %    rpt = Report("myrpt", 'pdf');
            %
            %    sec = Section("Title", "Introduction");
            %    titleRptr = getTitleReporter(sec);
            %    % MyCustomTemplate contains customized version of standard
            %    % template SectionNumberedTitle1.
            %    titleRptr.TemplateSrc = "MyCustomTemplate.pdftx';
            %    titleRptr.OutlineLevel = 1;
            %    sec.Title = titleRptr;
            %    append(rpt, sec);
            %    close(rpt);
            % 
            %
            %    Default SectionTitle Properties
            %
            %    You can customize the title format by changing the default
            %    values for the following properties.
            %
            %    TemplateSrc
            %
            %    Set by default to Section reporter template. This
            %    template's template library contains default section title
            %    templates named SectionTitle1, SectionTitle2, etc., for
            %    unnumbered titles and SectionNumberedTitle1,
            %    SectionNumberedTitle2, etc., for hierarchically numbered
            %    titles. You can set this property to the source of a
            %    template file that contains custom definitions of these
            %    templates.
            %
            %    TemplateName
            %
            %    Set by default to SectionNumberedTitle if the Section
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
            %    Left empty by default. The Section reporter getImpl
            %    method, which invokes this method by default, sets this
            %    property to a section level when the Section reporter is
            %    added to the report. The SectionTitle reporter then
            %    appends the OutlineLevel to the TemplateName to create the
            %    full name of the SectionTitle template for the Section
            %    level, e.g., SectionNumberedTitle2 for a second-level
            %    subsection.
            %
            %    Content
            %
            %    Set by default to the value of the Section reporter Title
            %    property.
            %
            %    NumberPrefix
            %
            %    Set by default to [].
            %
            %    NumberSuffix
            %
            %    Set to ". " if the Section Numbered property is true (the
            %    default; otherwise, to [].`
            %
            %    HoleId
            %
            %    Set to Title by default. Do not change this setting.
            %
            %    Translations
            %
            %    Not set by default. Set this property to localize the
            %    section title number prefix and suffix title content. See
            %    the help for the Translations property for more
            %    information.
            %
            %    See also mlreportgen.report.Section.Title, 
            %    mlreportgen.report.SectionTitle
        end

        function out=number(~) %#ok<STOUT>
            %  mlreportgen.report.Section.number(rpt, value)
            %     If value is true, number report sections consecutively.
            %     You can use a section's Numbered property to override
            %     this setting.
            %
            %     Example
            %
            %     % Turn off report section numbering.
            %     import mlreportgen.report.*
            %     import mlreportgen.dom.*
            %     rpt = Report('My Report', 'pdf');
            %     mlreportgen.report.Section.number(rpt, false);
            %     add(rpt, TitlePage('Title', 'My Report'));
            %     append(rpt, TableOfContents);
            %     append(rpt, Chapter('Title',  'Boeing 747', ...
            %         'Content', Image(which('b747.jpg'))));
            %     append(rpt, Chapter('Title',  'Peppers', ...
            %         'Content', Image(which('peppers.png'))));
            %     close(rpt);
            %     rptview(rpt);
            %
            %     See also mlreportgen.report.Section.Numbered
        end

    end
    properties
        % Content Content of this section
        %
        % The value of this property is the section content. The value 
        % can be any of the following types of objects
        %
        %        - MATLAB string
        %        - character array
        %        - DOM objects that can be added to a DOM document part
        %        - reporters, including Section reporters
        %        - 1xN or Nx1 array of MATLAB strings, character arrays,
        %          DOM objects, or reporters
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          DOM objects, or reporters
        %
        % You must use the Section constructor or add method to set this
        % property. You cannot set it directly.
        %
        % See also mlreportgen.report.Section,
        % mlreportgen.report.Section.add
        Content;

        % Numbered Whether to number this section
        %    If the value of this property is [] or true, the section is
        %    numbered relative to other sections in the report. The section
        %    number appears in its title. If the value of this property is
        %    false, this section is not numbered. A true or false value for
        %    this property overrides the numbering specified for the report
        %    as a whole by the mlreportgen.report.Section.number
        %    
        %    See also mlreportgen.report.Section.number
        Numbered;

        % Title Section title
        %    Specifies the text of the section title. The value of this
        %    property may be a
        %        - MATLAB string
        %        - character array
        %        - DOM object
        %        - 1xN or Nx1 array of strings or DOM objects
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          and/or DOM objects
        %        - Reporter returned by this section's getTitleReporter
        %          method
        %
        %    If the value is an inline object, i.e., an object that a
        %    paragraph can contain, the section object uses one of a set of
        %    templates stored in its template library to create a title
        %    based on the value. The template used depends on whether the
        %    title is to be numbered and the section's level in the
        %    report's section hierarchy. Use the section's Numbered 
        %    property to specify whether the section title should be
        %    numbered. You can use inline DOM objects, e.g., the Text
        %    object, to override the character formatting specified by
        %    the section's default title templates.
        %
        %    Example
        %
        %    import mlreportgen.report.*
        %    import mlreportgen.dom.*
        %    sect = Section;
        %    sect.Title = Text('A Section');
        %    sect.Title.Color = 'blue'; % Overrides default color (black)
        %
        %    If the value of the title is a DOM paragraph or other DOM
        %    block object, the section inserts the object at the beginning
        %    of the section. This allows you to use block elements to
        %    customize the spacing, alignment, and other properties of
        %    the section title. In this case, you must fully specify 
        %    the title format and must provide title numbering yourself.
        %
        %    Example
        %    
        %    The following example generates a report with centered
        %    subsection titles that are numbered, using DOM autonumbers.
        %    The DOM API does not support mixing template-based autonumbers
        %    and programmatic autonumbers. For this reason, this example
        %    also programmatically generates numbered chapter titles as
        %    well as subsection titles.
        %
        %    import mlreportgen.report.*
        %    import mlreportgen.dom.*
        %    rpt = Report('My Report', 'html');
        %    append(rpt, TitlePage('Title', 'My Report'));
        %    append(rpt, TableOfContents);
        %    chTitle = Heading1('Chapter ');
        %    chTitle.Style = { CounterInc('sect1'), WhiteSpace('preserve') ...
        %         Color('black'), Bold, FontSize('24pt')};
        %    append(chTitle, AutoNumber('sect1'));
        %    append(chTitle, '. ');
        %    sectTitle = Heading2();
        %    sectTitle.Style = { CounterInc('sect2'), WhiteSpace('preserve') ...
        %         HAlign('center'), PageBreakBefore};
        %    append(sectTitle, AutoNumber('sect1'));
        %    append(sectTitle, '.');
        %    append(sectTitle, AutoNumber('sect2'));
        %    append(sectTitle, '. '); 
        %    title = clone(chTitle);
        %    append(title, 'Images');
        %    ch = Chapter('Title', title);
        %    title = clone(sectTitle());
        %    append(title, 'Boeing 747');
        %    append(ch, Section('Title', title, 'Content', Image(which('b747.jpg'))));
        %    title = clone(sectTitle());
        %    append(title, 'Peppers');
        %    append(ch, Section('Title', title, 'Content', Image(which('peppers.png'))));
        %    append(rpt, ch);
        %    close(rpt);
        %    rptview(rpt);
        %
        %    See also mlreportgen.report.Section.Numbered,
        %    mlreportgen.dom.Heading, mlreportgen.dom.Autonumber,
        %    mlreportgen.dom.Text,
        %    mlreportgen.report.Section.getTitleReporter
        Title;

    end
end
