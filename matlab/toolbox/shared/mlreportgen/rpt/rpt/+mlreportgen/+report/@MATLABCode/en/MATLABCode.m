classdef MATLABCode< mlreportgen.report.Reporter
%mlreportgen.report.MATLABCode Create a reporter that reports syntax-highlighted MATLAB code
%   reporter = MATLABCode() creates an empty MATLABCode reporter object
%   based on a default template. Use its properties to specify a MATLAB
%   code file (.m or .mlx) or MATLAB code content on which to report
%   and to specify the report options. You must specify the MATLAB file
%   or MATLAB code content to be reported. Adding an empty MATLABCode
%   reporter object, that is, one that does not specify a MATLAB file
%   or code content, to a report, produces an error.
%
%   reporter = MATLABCode(filename) creates a MATLABCode reporter to
%   report on the specified MATLAB code file (.m or .mlx) content.
%   Adding this reporter to a report, without any further modification,
%   adds the file content to the generated report as syntax-highlighted
%   code. Use the reporter’s properties to customize the report
%   options.
%
%   reporter = MATLABCode(p1=v1,p2=v2,...) creates a MATLABCode
%   reporter and sets its properties (p1,p2, ...) to the specified
%   values (v1,v2, ...).
%
%   MATLABCode properties:
%     FileName              - MATLAB code file name
%     Content               - MATLAB code content
%     SmartIndent           - Whether to smart indent MATLAB code
%     IncludeComplexity     - Whether to include code complexity
%     ComplexityReporter    - Code complexity reporter
%     TemplateSrc           - Source of this reporter's template
%     TemplateName          - Name of this reporter's template
%     LinkTarget            - Hyperlink target for this reporter's content
%
%   MATLABCode methods:
%     getClassFolder        - Get location of folder that contains this class
%     createTemplate        - Copy the default MATLABCode template
%     customizeReporter     - Subclasses MATLABCode for customization
%     getImpl               - Get DOM implementation for this reporter
%     getSyntaxColoredCode  - Get DOM object containing a syntax-colored code
%
%   Example:
%
%       % Create a MATLAB code file "my_script.m" on which to report
%
%       % Create a report
%       rpt = mlreportgen.report.Report("MyReport","pdf");
%
%       % Create a chapter
%       chap = mlreportgen.report.Chapter("MATLABCode Reporter Example");
%
%       % Create MATLABCode reporter to report on "my_script.m" content
%       mCode = mlreportgen.report.MATLABCode("my_script.m");
%
%       % Add reporter to the chapter and chapter to the report
%       append(chap,mCode);
%       append(rpt,chap);
%
%       % Close the report and open the viewer
%       close(rpt);
%       rptview(rpt);

     
    % Copyright 2020-2024 The MathWorks, Inc.

    methods
        function out=MATLABCode
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template = mlreportgen.report.MATLABCode.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the MATLABCode
            %    reporter template specified by type at the location
            %    specified by templatePath. You can use this method to
            %    create a copy of a default MATLABCode reporter template
            %    to serve as a starting point for creating your own custom
            %    template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % classfile = mlreportgen.report.MATLABCode.customizeReporter(toClasspath)
            %    is a static method that creates an empty class derived
            %    from the MATLABCode reporter class with the name
            %    toClasspath. You can use the generated class as a starting
            %    point for creating your own custom version of the
            %    MATLABCode reporter.
            %
            %    For example:
            %    mlreportgen.report.MATLABCode.customizeReporter("path_folder/MyMATLABCode.m")
            %    mlreportgen.report.MATLABCode.customizeReporter("+myApp/@MATLABCode")
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = mlreportgen.report.MATLABCode.getClassFolder()
            %    is a static method that returns the path of the folder
            %    that contains the definition of this class.
        end

        function out=getImpl(~) %#ok<STOUT>
        end

        function out=getSyntaxColoredCode(~) %#ok<STOUT>
            % syntaxColoredDOMObject = syntaxColoredDOMObject(this,rpt)
            % returns a DOM object containing a syntax-colored rendition of
            % the code that this reporter generates. The below table shows
            % which DOM object is returned depending on the source
            % specified for this reporter and the output type of report.
            %
            % MATLAB Code Source    Report Type        DOM Object
            % ------------------    --------------     --------------
            % .mlx                  html,html-file     RawText
            % .mlx                  docx               EmbeddedObject
            % .mlx                  pdf                HTML
            % .m (or, if the        html,html-file,    HTMLFile
            % content is specified  pdf,docx
            % directly using the
            % Content property)
            %
            % See also mlreportgen.dom.RawText, mlreportgen.dom.HTML,
            % mlreportgen.dom.EmbeddedObject, mlreportgen.dom.HTMLFile
        end

    end
    properties
        %ComplexityReporter Code complexity reporter
        %    Specifies the reporter to be used to report and format code
        %    complexity tabular data. The default value of this property is
        %    an mlreportgen.report.BaseTable object. You can customize the
        %    appearance of the table by customizing the default reporter or
        %    by replacing it with a customized version of the BaseTable
        %    reporter. See the BaseTable documentation or command-line help
        %    for information on customizing this reporter. Any content that
        %    you specify in the Title property of the default or the
        %    replacement reporter will appear before the title in the
        %    generated report.
        %
        %    See also mlreportgen.report.BaseTable
        ComplexityReporter;

        % Content MATLAB code content
        %    Specifies the MATLAB code content to be reported. Specify this
        %    property only if FileName is not set. The value of this
        %    property can be specified as a character vector or a string
        %    scalar.
        Content;

        % FileName MATLAB code file name
        %    Specifies the path and name of the MATLAB code file (.m or .mlx)
        %    whose content needs to be reported. Setting this property
        %    auto-populates the Content property with the content of the
        %    specified file. The value of this property can be specified as
        %    a character vector or a string scalar.
        FileName;

        % IncludeComplexity Whether to include code complexity
        %    If true, the report includes the McCabe cyclomatic complexity
        %    of each function in the MATLAB code. The default value is
        %    false.
        %
        %    See also checkcode
        IncludeComplexity;

        % SmartIndent Whether to smart indent MATLAB code
        %    If true, smart indenting is applied to the MATLAB code before
        %    reporting. The default value is false.
        SmartIndent;

    end
end
