classdef TextFile< mlreportgen.report.Reporter
%mlreportgen.report.TextFile Create a reporter that reports on a text
%   file.
%
%   reporter = TextFile() creates an empty TextFile reporter object
%   based on a default template. Use its properties to specify a text
%   file on which to report and to specify report options. You must
%   specify a text file name to be reported. Adding an empty TextFile
%   reporter object, that is, one that does not specify a file name,
%   to a report, produces an error.
%
%   reporter = TextFile(filename) creates a TextFile reporter object
%   with the FileName property set to filename. Adding this reporter
%   to a report, without any further modification, adds the text file
%   content to the generated report. Use the reporter's properties to
%   customize the report options.
%
%   reporter = TextFile(p1=v1,p2=v2,...) creates a TextFile reporter
%   and initializes properties (p1,p2,...) to the specified values
%   (v1,v2,...).
%
%   TextFile properties:
%     FileName               - Path or name of a text file
%     ImportFileAsParagraph  - Whether to import text content as paragraph
%     ParaSep                - Separator to break the input up into paragraphs
%     ParagraphFormatter     - TextFile paragraph formatter
%     TextFormatter          - TextFile text formatter
%     TemplateSrc            - Source of this reporter's template
%     TemplateName           - Name of this reporter's template
%     LinkTarget             - Hyperlink target for this reporter's content
%
%   TextFile methods:
%     getClassFolder         - Get location of folder that contains this class
%     createTemplate         - Create copy of default TextFile template
%     customizeReporter      - Create subclass of TextFile for customization
%     getImpl                - Get DOM implementation for this reporter
%
%   Example:
%
%     % Create a text file "my_script.txt" on which to report
%
%     % Import the Report API package
%     import mlreportgen.report.*
%
%     % Create a report
%     rpt = Report("MyReport","pdf");
%     open(rpt);
%
%     % Create a chapter
%     chap = Chapter("TextFile Reporter");
%
%     % Report on txt-file content using TextFile reporter
%     rptr = TextFile("my_script.txt");
%     rptr.ParaSep = [newline newline];
%
%     % Append reporter to the chapter and chapter to the report
%     append(chap,rptr);
%     append(rpt,chap);
%
%     % Close and view the report
%     close(rpt);
%     rptview(rpt);

 
    % Copyright 2022-2023 The MathWorks, Inc.

    methods
        function out=TextFile
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.TextFile.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the TextFile
            %    reporter template specified by type at the location
            %    specified by templatePath. You can use this method to
            %    create a copy of a default TextFile reporter template
            %    to serve as a starting point for creating your own custom
            %    template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % classfile = mlreportgen.report.TextFile.customizeReporter(toClasspath)
            %    is a static method that creates an empty class derived
            %    from the TextFile reporter class with the name
            %    toClasspath. You can use the generated class as a starting
            %    point for creating your own custom version of the
            %    TextFile reporter.
            %
            %    For example:
            %    mlreportgen.report.TextFile.customizeReporter("path_folder/MyTextFile.m")
            %    mlreportgen.report.TextFile.customizeReporter("+myApp/@TextFile")
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = mlreportgen.report.TextFile.getClassFolder()
            %    is a static method that returns the path of the folder
            %    that contains the definition of this class.
        end

        function out=getImpl(~) %#ok<STOUT>
        end

    end
    properties
        % FileName Path or name of a text file
        %    Specifies the path or name of a text file. The value of this
        %    property can be specified as a character vector or a string
        %    scalar.
        %
        %    See also mlreportgen.report.MATLABCode to report on
        %    syntax-highlighted MATLAB code
        FileName;

        % ImportFileAsParagraph Whether to import text content as paragraph
        %    This property specifies whether to import the text file as a
        %    DOM Paragraph, or Text object. This property may be either
        %    true, or false, with true being the default value.
        %
        %    Valid values:
        %
        %    true  - (default) When this property is set to true, it
        %            imports the text file as DOM Paragraph object. It
        %            breaks the file content into one or more DOM
        %            paragraph objects at values specified by the ParaSep
        %            property. Use ParagraphFormatter property whose value
        %            is a DOM Paragraph object to format the DOM Paragraph
        %            objects.
        %
        %    false - When this property is set to false, it imports the
        %            text file as a DOM Text object. Use TextFormatter
        %            property whose value is a DOM Text object to format
        %            the DOM Text object.
        %
        %   See also mlreportgen.report.TextFile.ParagraphFormatter,
        %   mlreportgen.report.TextFile.TextFormatter
        ImportFileAsParagraph;

        % ParaSep Specifies separator used in plain text content to delimit
        %        paragraphs. This property breaks the text file content
        %        into one or more DOM paragraphs depending on the separator
        %        specified. The value of this property can be specified as
        %        a character vector or a string scalar. The default value
        %        is specified as an empty array of class double i.e., []
        %        that wraps the file content in a single paragraph
        %        regardless of whether it contains seprators. You can
        %        specify any custom separator.
        %
        %        Some custom separator examples are as follows:
        %        - newline, or char(10), or sprintf('\n'), or
        %          [char(13) char(10)], or sprintf('\r\n')
        %        - [newline newline], or [char(10) char(10)], or
        %          sprintf('\n\n'), [char(13) char(10) char(13) char(10)],
        %          or sprintf('\r\n\r\n')
        %        - "\r\n" or "\n"
        %        - "\r\n\r\n" or "\n\n"
        %        - "," (comma separator)
        %        - "\"  (File path seprator)
        ParaSep;

        % ParagraphFormatter TextFile paragraph formatter
        %   The default value of this property is a DOM Paragraph object.
        %   If this reporter's ImportFileAsParagraph property is true, a
        %   plain text paragraph is appended to a copy of this object,
        %   which is then appended to a report. This allows you to format a
        %   plain text paragraph either by setting the properties of the
        %   default paragraph or by replacing the default paragraph with a
        %   custom paragraph. Any content that you add to the default or
        %   replacement paragraph appears before the actual content in the
        %   generated report.
        %
        %   See also mlreportgen.report.TextFile.ImportFileAsParagraph,
        %   mlreportgen.dom.Paragraph
        ParagraphFormatter;

        % TextFormatter TextFile text formatter
        %    The default value of this property is a DOM Text object. If
        %    this reporter's ImportFileAsParagraph property is false,
        %    plain text content is appended to a copy of this object,
        %    which is then appended to a report. This allows you to format
        %    plain text content either by setting the properties of the
        %    default text object or by replacing the default text object
        %    with a custom object. Any content that you add to the default
        %    or replacement text appears before the actual content in the
        %    generated report.
        %
        %   See also mlreportgen.report.TextFile.ImportFileAsParagraph,
        %   mlreportgen.dom.Text
        TextFormatter;

    end
end
