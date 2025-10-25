classdef TitlePage< mlreportgen.report.Reporter
% mlreportgen.report.TitlePage Create a title page reporter
%    tp = TitlePage() creates a title page reporter that uses the
%    default title page template.
%
%    tp = mlreportgen.report.TitlePage(p1, v1, p2, v2,...) creates a
%    title page and sets its properties (p1, p2, ...) to the specified
%    values (v1, v2, ...).
%
%    TitlePage properties:
%      Title          - Report title
%      Subtitle       - Report subtitle
%      Image          - Title page image
%      Author         - Report author
%      Publisher      - Report publisher
%      PubDate        - Report publication date
%      TemplateSrc    - Source of this reporter's template
%      TemplateName   - Template name in source template library
%      LinkTarget     - Hyperlink target for title page
%      Layout         - Page layout of title page
%
%
%    TitlePage methods:
%      getClassFolder         - Get location of folder that contains this class
%      createTemplate         - Copy the default title page template
%      customizeReporter      - Subclasses TitlePage for customization
%      getImpl                - Get DOM implementation for this reporter
%      getTitleReporter       - Get reporter that formats title
%      getSubtitleReporter    - Get reporter that formats subtitle
%      getImageReporter       - Get reporter that formats image
%      getAuthorReporter      - Get reporter that formats author
%      getPublisherReporter   - Get reporter that formats publisher
%      getPubDateReporter     - Get reporter that formats report date
%
%    Example
%
%    report = mlreportgen.report.Report('output','pdf');
%
%    tp = mlreportgen.report.TitlePage();
%    tp.Title = 'Title Page Example';
%    tp.Subtitle = 'Report API';
%    tp.Image = which('b747.jpg');
%    tp.Publisher = 'MathWorks';
%    tp.PubDate = date();
%    % add the title page reporter to the report
%    add(report,tp);
%
%    % close and view the output document
%    close(report);
%    rptview(report);
%
%    Customize TitlePage Element Format
%
%    A TitlePage objects uses a template to determine the alignment,
%    position, and text format of its title, subtitle, author, and other
%    elements. You can use DOM objects to override the formats and
%    layouts:
%
%    Example
%
%    % Override default title color
%    import mlreportgen.dom.*
%    import mlreportgen.report.*
%    tp = TitlePage;
%    tp.Title = Text('System Design Description');
%    tp.Title.Color = 'red';
%
%
%    Example
%
%    % Override default title position
%    import mlreportgen.dom.*
%    import mlreportgen.report.*
%    tp = TitlePage;
%    tp.Title = Paragraph('System Design Description');
%    tp.Title.Style = {HAlign('left'), FontFamily('Arial'), ...
%        FontSize('24pt'), Color('white'), BackgroundColor('blue'), ...
%        OuterMargin('0in', '0in', '.5in', '1in'),HAlign('center')};
%
%    You can also override the appearance and layout of title page
%    elements by overriding the element templates themselves. The
%    TitlePage reporter supports two approaches to overriding the
%    title page element templates.
%
%    Use Custom TitlePage Template
%
%    1. Create a copy of the default title page template.
%
%    2. Edit the title page element templates in the copy of the
%       template to meet your requirements. The names of the templates
%       have the form TitlePageNAME where NAME is the name of the
%       template in the template library. For example, the name of
%       the title template is TitlePageTitle.
%
%    3. Set the TitlePage object's TemplateSrc property to the path
%       of the custom template.
%
%    Use Third-Party Template Library
%
%    This approach takes advantage of the fact that the TitlePage
%    object uses specialized reporters, called hole reporters, to
%    apply the element templates to the elements. The TitlePage
%    reporter provides methods for getting the reporter used to apply
%    a template to a particular element. For example, the
%    getTitleReporter method returns the reporter used to apply the
%    TitlePageTitle template to the report's title content.
%
%    1. Copy the title page element templates that you need to 
%       customize into the template library of another template used by
%       your report, for example, the template library of the report
%       template or the template library of a DOM document part object
%       that you have created specifically to store customized versions
%       of templates stored in the template libraries of reporters 
%       used by your report.
%
%    2. For each title page element to be customized, get the element's
%       reporter.
%  
%    3. Set the element reporter's TemplateSrc property to the source
%       of the third-party template library containing the customized
%       version of the element template.
%
%    4. Set the element reporter's Content property to the element
%       content.
%
%    5. Set the title page object's element property to the element
%       reporter object.
%
%    Example
%
%    import mlreportgen.report.*
%    import mlreportgen.dom.*
%
%    rpt = Report('MyReport', 'pdf', 'MyCustomPDFTemplate');
%    tp = TitlePage;
%    titleReporter = getTitleReporter(tp);
%    titleReporter.TemplateSrc = rpt; % Contains custom title template
%    titleReporter.Content = 'My Report';
%    tp.Title = titleReporter;
%
%    Customize Page Layout
%
%    A TitlePage object's template determines its page orientation,
%    page margins, page size, and other page layout properties. You
%    can use the title page object's Layout property to override
%    some default layout properties programmatically. You can fully
%    customize the title page's page layout using a customized version
%    of its default template.
%
%    See also mlreportgen.report.TitlePage.Layout,
%    mlreportgen.report.TitlePage.createTemplate.

     
    %    Copyright 2017-2023 The MathWorks, Inc.

    methods
        function out=TitlePage
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.TitlePage.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the TitlePage
            %    template specified by type at the location specified by
            %    templatePath. You can use this method to create a copy of
            %    the default TitlePage template to serve as a starting
            %    point for creating your own custom template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % path = mlreportgen.report.TitlePage.customizeReporter(path)
            %    is a static method that creates a class definition file
            %    that defines a subclass of mlreportgen.report.TitlePage
            %    class. You can use this file as a starting point for
            %    defining a custom title page class. The path argument is a
            %    string that specifies the path of the class definition
            %    file to be created.
            %
            %    Example
            %
            %    mlreportgen.report.TitlePage.customizeReporter("+myApp/@MyTitlePage")
            %
            %    defines a TitlePage subclass named myApp.MyTitlePage.
        end

        function out=getAuthorReporter(~) %#ok<STOUT>
            %getAuthorReporter Gets the TitlePage Author reporter
            % reporter = getAuthorReporter(tp) returns a reporter that
            % the TitlePage reporter uses to format the content specified
            % by the value of its Author property. You can use this
            % reporter to customize the author alignment, position, and
            % appearance. See the TitlePage help for more information.
            %
            % See also mlreportgen.report.TitlePage.Author,
            % mlreportgen.report.TitlePage
        end

        function out=getClassFolder(~) %#ok<STOUT>
            %mlreportgen.report.TitlePage.getClassFolder
            % path = getClassFolder() returns the path of the folder that
            % contains the class definition file.
        end

        function out=getImageReporter(~) %#ok<STOUT>
            %getImageReporter Gets the TitlePage Image reporter
            % reporter = getImageReporter(tp) returns a reporter that the
            % TitlePage reporter uses to format the content specified by
            % the value of its Image property. You can use this reporter to
            % customize the image position and alignment. See the TitlePage
            % help for more information.
            %
            % See also mlreportgen.report.TitlePage.Image,
            % mlreportgen.report.TitlePage
        end

        function out=getPubDateReporter(~) %#ok<STOUT>
            %getPubDateReporter Gets the TitlePage PubDate reporter
            % reporter = getPubDateReporter(tp) returns a reporter that
            % the TitlePage reporter uses to format the content specified
            % by the value of its PubDate property. You can use this
            % reporter to customize the date alignment, position, and
            % appearance. See the TitlePage help for more information.
            %
            % See also mlreportgen.report.TitlePage.PubDate,
            % mlreportgen.report.TitlePage
        end

        function out=getPublisherReporter(~) %#ok<STOUT>
            %getPublisherReporter Gets the TitlePage Publisher reporter
            % reporter = getPublisherReporter(tp) returns a reporter that
            % the TitlePage reporter uses to format the content specified
            % by the value of its Publisher property. You can use this
            % reporter to customize the publisher alignment, position, and
            % appearance. See the TitlePage help for more information.
            %
            % See also mlreportgen.report.TitlePage.Publisher,
            % mlreportgen.report.TitlePage
        end

        function out=getSubtitleReporter(~) %#ok<STOUT>
            %getSubtitleReporter Gets the TitlePage Subtitle reporter
            % reporter = getSubtitleReporter(tp) returns a reporter that
            % the TitlePage reporter uses to format the content specified
            % by the value of its Subtitle property. You can use this
            % reporter to customize the subtitle alignment, position, and
            % appearance. See the TitlePage help for more information.
            %
            % See also mlreportgen.report.TitlePage.Subtitle,
            % mlreportgen.report.TitlePage
        end

        function out=getTitleReporter(~) %#ok<STOUT>
            %getTitleReporter Gets the TitlePage Title reporter
            % reporter = getTitleReporter(tp) returns a reporter that the
            % TitlePage reporter uses to format the content specified by
            % the value of its Title property. You can use this reporter to
            % customize the title alignment, position, and appearance. See
            % the TitlePage help for more information.
            %
            % See also mlreportgen.report.TitlePage.Title,
            % mlreportgen.report.TitlePage
        end

    end
    properties
        % Author Report author
        %    Specifies the content of the report author element. You can
        %    use any of the following to specify the author content
        %
        %        - MATLAB string
        %        - character array
        %        - DOM object
        %        - 1xN or Nx1 array of strings or DOM objects
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          and/or DOM objects
        %        - Reporter created by this title pages getAuthorReporter
        %          method
        %
        %    The default value of this property is the MATLAB logged-in
        %    user name. If the user is not logged-in, the default value of
        %    this property is the value of the environment variable
        %    username. If the username variable is not found, then this
        %    property returns an empty default value.
        %
        %    See also mlreportgen.report.TitlePage.getAuthorReporter
        Author;

        % Image Title page image
        %    Specifies an image to insert in the title page. The value
        %    of this property may be
        %
        %    - MATLAB string or character array that specifies the file
        %      system path of the image
        %    - Snapshot maker, such as a Figure reporter
        %    - DOM object
        %    - 1xN or Nx1 array or cell array of image paths, snapshot
        %      makers, or DOM objects
        %    - Reporter created by this title page's getImageReporter
        %      method
        %
        %    tp = TitlePage();
        %    tp.Image = mlreportgen.dom.Image(which('b747.jpg'));
        %    tp.Image.Width = '8.5in';       
        %    tp.Image.Height = [];
        %
        %    See also mlreportgen.report.TitlePage.getImageReporter
        Image;

        % Layout Page layout of title page
        %   This property allows you to override some properties, such as
        %   page orientation, of the page layout specified by the title
        %   page's template. 
        %
        %   Example
        %
        %   import mlreportgen.report.*
        %   tp = TitlePage
        %   tp.Layout.Landscape = true;
        %
        % See also mlreportgen.report.ReporterLayout
        Layout;

        % PubDate Report publication date
        %    Specifies the content of the report publication date element.
        %    You can use any of the following to specify the date content
        %
        %        - MATLAB string
        %        - character array
        %        - DOM object
        %        - 1xN or Nx1 array of strings or DOM objects
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          and/or DOM objects
        %        - Reporter created by this title page's getPubDateReporter
        %          method
        %
        %    See also mlreportgen.report.TitlePage.getPubDateReporter
        PubDate;

        % Publisher Report publisher
        %    Specifies the content of the report publisher element. You can
        %    use any of the following to specify the publisher content
        %
        %        - MATLAB string
        %        - character array
        %        - DOM object
        %        - 1xN or Nx1 array of strings or DOM objects
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          and/or DOM objects
        %        - Reporter created by this title page's 
        %          getPublisherReporter method
        %    
        %    See also mlreportgen.report.TitlePage.getPublisherReporter
        Publisher;

        % Subtitle Report subtitle
        %    Specifies the content of the report title. You can use any of
        %    the following to specify the title content
        %
        %        - MATLAB string
        %        - character array
        %        - DOM object
        %        - 1xN or Nx1 array of strings or DOM objects
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          and/or DOM objects
        %        - Reporter created by this title page's 
        %          getSubtitleReporter method
        %
        %    See also mlreportgen.report.TitlePage.getSubtitleReporter
        Subtitle;

        % Title Report title
        %    Specifies the content of the report title. You can use any of
        %    the following to specify the title content
        %
        %        - MATLAB string
        %        - character array
        %        - DOM object
        %        - 1xN or Nx1 array of strings or DOM objects
        %        - 1xN or Nx1 cell array of strings, character arrays,
        %          and/or DOM objects
        %        - Reporter created by this title page's getTitleReporter
        %          method
        %
        %    Example
        %
        %    import mlreportgen.report.*
        %    tp = TitlePage;
        %    tp.Title = 'System Design Description'
        %
        %    See also mlreportgen.report.TitlePage.getTitleReporter
        Title;

    end
end
