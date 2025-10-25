classdef MATLABVariable< mlreportgen.report.Reporter & mlreportgen.report.internal.VariableBase
%mlreportgen.report.MATLABVariable Create a reporter that reports on a MATLAB variable
%   reporter = MATLABVariable() creates an empty MATLAB variable
%   reporter object based on a default template. Use its properties to
%   specify a variable name on which to report and to specify the
%   report options. You must specify the variable name to be reported.
%   Adding an empty MATLAB variable reporter object to a report
%   produces an error.
%
%   reporter = MATLABVariable(variable) creates a MATLAB variable
%   reporter object for the specified MATLAB workspace variable name or
%   a local variable that is specified directly. Adding this reporter
%   to a report, without any further modification, adds variable
%   information based on default settings. Use the reporters
%   properties to specify the report options.
%
%   reporter = MATLABVariable('p1', v1, 'p2', v2,...) creates MATLAB
%   variable reporter object and sets its properties (p1, p2, ...) to
%   the specified values (v1, v2, ...). Instead of specifying the
%   variable's string name, a local variable can also be specified
%   directly as the value for the "Variable" property in this
%   constructor.
%
%   MATLABVariable properties:
%     Variable             - Variable name
%     Location             - Location of the variable
%     FileName             - File name that stores the variable
%     FormatPolicy         - Format policy for the variable values
%     TableReporter        - MATLAB variable table reporter
%     ParagraphFormatter   - MATLAB variable paragraph formatter
%     TextFormatter        - MATLAB variable text formatter
%     MaxCols              - Maximum number of table columns to display
%     DepthLimit           - Number of nested levels to report
%     ObjectLimit          - Number of nested objects to report
%     IncludeTitle         - Whether to include title
%     Title                - Title of variable to report
%     ShowDataType         - Whether to show variable's data type in title
%     ShowEmptyValues      - Whether to show properties with empty values
%     ShowDefaultValues    - Whether to show properties with default values
%     PropertyFilterFcn    - Function handle or code to filter properties
%     NumericFormat        - Format or precision used to display noninteger values
%     TemplateSrc          - Source of this reporter's template
%     TemplateName         - Name of this reporter's template
%     LinkTarget           - Hyperlink target for this reporter's content
%
%   MATLABVariable methods:
%     setVariableValue     - Set the value to report for the variable
%     getVariableValue     - Get the value of the specified variable
%     getVariableName      - Get the name of the specified variable
%     getClassFolder       - Get location of folder that contains this class
%     createTemplate       - Copy the default MATLAB variable template
%     customizeReporter    - Subclasses MATLABVariable for customization
%     getImpl              - Get DOM implementation for this reporter
%
%    Example:
%
%         % Create a Report
%         rpt = mlreportgen.report.Report("MyReport","pdf");
%
%         % Create a Chapter
%         chapter = mlreportgen.report.Chapter();
%         chapter.Title = "MATLAB Variable Reporter Example";
%
%         % To report on a local variable defined in the current scope:
%         % Define the local variable
%         local_var = "Hello World!";
%
%         % Create a MATLABVariable reporter object to report on this
%         % local variable by directly specifying the variable in the
%         % constructor
%         reporter = mlreportgen.report.MATLABVariable(local_var);
%
%         % Add the reporter to the chapter
%         add(chapter,reporter);
%
%         % To report on a variable defined in base workspace:
%         % Define a variable in the base workspace as:
%         % >> base_var = "Hello World!";
%
%         % Create a MATLABVariable reporter object to report on the
%         % variable defined in the base workspace by providing the
%         % variable name as string
%         reporter = mlreportgen.report.MATLABVariable("base_var");
%
%         % Add the reporter to the chapter
%         add(chapter,reporter);
%
%         % Add chapter to the report
%         add(rpt,chapter);
%
%         % Close the report and open the viewer
%         close(rpt);
%         rptview(rpt);

     
    %   Copyright 2018-2023 The MathWorks, Inc.

    methods
        function out=MATLABVariable
        end

        function out=createTemplate(~) %#ok<STOUT>
            % template =
            % mlreportgen.report.MATLABVariable.createTemplate(templatePath,type)
            %    is a static method that creates a copy of the
            %    MATLABVariable reporter template specified by
            %    type at the location specified by templatePath. You can
            %    use this method to create a copy of a default
            %    MATLABVariable reporter template to serve as a
            %    starting point for creating your own custom template.
        end

        function out=customizeReporter(~) %#ok<STOUT>
            % classfile = mlreportgen.report.MATLABVariable.customizeReporter(toClasspath)
            %    is a static method that creates an empty class derived from the
            %    MATLABVariable reporter class with the name toClasspath. You can use the
            %    generated class as a starting point for creating your own custom
            %    version of the MATLABVariable reporter.
            %
            %    For example:
            %    mlreportgen.report.MATLABVariable.customizeReporter("path_folder/MyMATLABVariable.m")
            %    mlreportgen.report.MATLABVariable.customizeReporter("+myApp/@MATLABVariable")
        end

        function out=getClassFolder(~) %#ok<STOUT>
            % path = mlreportgen.report.MATLABVariable.getClassFolder()
            %    returns the folder location which contains this class.
        end

        function out=getImpl(~) %#ok<STOUT>
        end

        function out=getVariableName(~) %#ok<STOUT>
            % name = getVariableName(this) returns the name of the
            % variable to be reported.
        end

        function out=getVariableValue(~) %#ok<STOUT>
            % value = getVariableValue(this) returns the value of the
            % specified variable based on the specified variable location.
        end

        function out=setVariableValue(~) %#ok<STOUT>
            % setVariableValue(this, newValue) stores the value specified
            % by newValue in the reporter's properties and sets the
            % Location property of this reporter to "User-Defined". When
            % added to a report, the reporter reports the variable name
            % as defined in the Variable property and the variable value as
            % defined by this method.
            %
            % This method can be used to report values without creating a
            % variable for the value. For example, you can report an
            % individual entry in a containers.Map object with the
            % following code:
            %
            %   myMap = containers.Map(["key1", "key2"], [100, 200]);
            %   rptr = mlreportgen.report.MATLABVariable("key1");
            %   setVariableValue(rptr, myMap("key1"));
        end

    end
    properties
        % FileName File name that stores the variable
        %    Specifies the name of the .mat file to be used, if the
        %    variable to be reported needs to be fetched from a MAT file,
        %    i.e., the Location property is set to "MAT-File". If the
        %    Location property is set to "Model", this property specifies
        %    the file of the Simulink model containing the model workspace.
        FileName;

        % Location Location of the variable
        %    Specifies the location of the variable to be reported. The
        %    value of this property may be one of the following strings:
        %
        %       MATLAB       -  (default) Gets the variable from the base
        %                       workspace
        %       MAT-File     -  Gets the variable specified by the Variable
        %                       property from the MAT file specified by the
        %                       FileName property
        %       Global       -  Gets the global variable specified by the
        %                       Variable property
        %       Local        -  Gets the local variable from this reporters
        %                       scope, for e.g., a variable defined in the
        %                       same function as that of the MATLABVariable
        %                       reporter reporting on it.
        %       Model        -  Gets the variable specified by this reporter's
        %                       Variable property from the Simulink model
        %                       specified by this reporter's FileName
        %                       property. This option requires Simulink
        %                       Report Generator to be installed.
        %       User-Defined -  Gets the variable name specified by this
        %                       reporter's Variable property and reports
        %                       the value specified by this reporter's
        %                       setVariableValue method.
        Location;

        % Variable Variable name
        %    Specifies the name of the variable to be reported. Variable
        %    can have any of the following data types:
        %       - Character or character array
        %       - String
        %       - Cell vector or cell array
        %       - Logical scalar, logical vector, or logical array
        %       - Numeric scalar, numeric vector, or numeric array
        %       - MATLAB table
        %       - MATLAB structure, structure vector, or structure array
        %       - MATLAB object, object vector, or object array
        %       - Simulink object
        %       - Stateflow object
        %       - Graphics object
        %       - Enumeration
        %
        %    Note: Variable name must be specified as a string or character
        %    array. A local variable can be specified directly only in
        %    the constructors.
        Variable;

    end
end
