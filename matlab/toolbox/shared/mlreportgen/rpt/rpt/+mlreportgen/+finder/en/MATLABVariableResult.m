classdef MATLABVariableResult< mlreportgen.finder.Result
%mlreportgen.finder.MATLABVariableResult Container for an MATLABVariableFinder result
%   This class contains information about a variable in the MATLAB base
%   workspace, the global workspace, or a MAT file. The find method of
%   the mlreportgen.finder.MATLABVariableFinder class creates instances
%   of this class for the variables it finds. You do not need to create
%   MATLABVariableResult instances yourself.
%
%   Add a MATLABVariableResult object directly to a report, or use the
%   getReporter method to customize the MATLABVariable reporter that is
%   used to report on information contained in this result.
%
%   MATLABVariableResult properties:
%       Object              - Name of variable
%       Location            - Location of the variable
%       FileName            - MAT file that contains the variable
%       Tag                 - Tag to associate with result
%
%   MATLABVariableResult methods:
%       getReporter                     - Returns reporter for this variable
%       getDefaultSummaryTableTitle     - Returns the default variable summary table title
%       getDefaultSummaryProperties     - Returns the default properties reported when summarizing this result
%       getPropertyValues               - Returns the values of the specified properties of this variable
%       getReporterLinkTargetID         - Returns the link target ID of this result's reporter
%       getVariableValue                - Returns the value of the variable represented by this result
%
%   See also mlreportgen.finder.MATLABVariableFinder,
%   mlreportgen.report.MATLABVariable, mlreportgen.report.SummaryTable

 
    %   Copyright 2021 The MathWorks, Inc.

    methods
        function out=getDefaultSummaryProperties(~) %#ok<STOUT>
            % properties = getDefaultSummaryProperties(variableResult)
            % returns a string array of default properties to be reported
            % by the mlreportgen.report.SummaryTable class
            % when summarizing variable result objects. The default
            % properties reported are:
            %   - Name
            %   - Size
            %   - Bytes
            %   - Class
            %
            % See also mlreportgen.report.SummaryTable
        end

        function out=getDefaultSummaryTableTitle(~) %#ok<STOUT>
            % title = getDefaultSummaryTableTitle(variableResult) returns the
            % default summary table title used by the
            % mlreportgen.report.SummaryTable class if no title is
            % specified when summarizing variable results.
            %
            % See also mlreportgen.report.SummaryTable
        end

        function out=getPresenter(~) %#ok<STOUT>
        end

        function out=getPropertyValues(~) %#ok<STOUT>
            % propValues = getPropertyValues(variableResult,propertyNames)
            % gets the values of the properties specified in propertyNames
            % for the variable. The property values are returned in
            % propValues as a horizontal cell array. If propertyNames
            % contains any invalid properties, the corresponding value in
            % the cell array is "N/A". propValues can contain strings or
            % arrays of strings. Supported properties include:
            %   - Name          - Name of the variable
            %   - Value         - Value of the variable
            %   - Class         - Data type of the variable
            %   - Size          - Dimensions of the variable
            %   - Bytes         - Size of the variable in memory
            %   - Global        - Whether the variable is a global variable
            %   - Sparse        - Whether the variable is a sparse matrix
            %   - Complex       - Whether the variable is a complex value
            %   - Any property of variableResult
            %   - Any property of the variable that can be accessed using
            %     dot notation.
            %
            % See also mlreportgen.report.SummaryTable
        end

        function out=getReporter(~) %#ok<STOUT>
            % reporter = getReporter(MATLABVariableResult) returns a
            % MATLABVariable reporter that is used to include information
            % about a variable in a report. See the MATLABVariable reporter
            % help for more information on how to customize the reporter.
            %
            % See also mlreportgen.report.MATLABVariable
        end

        function out=getReporterLinkTargetID(~) %#ok<STOUT>
            % id = getReporterLinkTargetID(variableResult) returns the link
            % target ID of the reporter obtained by the variable result's
            % getReporter method. If the reporter's LinkTarget property is
            % empty, this method uses the default link target ID generated
            % by the reporter. Otherwise, this method returns the
            % link target ID in the reporter's LinkTarget property.
        end

        function out=getVariableValue(~) %#ok<STOUT>
            % value = getVariableValue(this) returns the value of the
            % variable represented by this result based on the variable
            % location.
        end

    end
    properties
        % FileName MAT File name that contains the variable
        %    This read-only property specifies the name of the MAT file
        %    where the variable is defined. This property only applies if
        %    the Location property of this result is "MAT-File". Otherwise,
        %    this property is an empty string.
        FileName;

        % Location Location of the variable
        %    This read-only property specifies the location of the variable
        %    to be reported. The location is specified as one of the
        %    following strings:
        %
        %       MATLAB       - The variable is defined in the base MATLAB
        %                      workspace
        %       MAT-File     - The variable is defined by the MAT file
        %                      specified in the FileName property
        %       Global       - The variable is defined in the global
        %                      workspace
        Location;

        % Object Name of variable
        %   This read-only property contains the name of the variable
        %   represented by this result, specified as a string.
        Object;

        %Tag Result identifier
        %   This property allows you to attach additional information to
        %   a result. You can set it to any value that meets your
        %   requirements.
        Tag;

    end
end
