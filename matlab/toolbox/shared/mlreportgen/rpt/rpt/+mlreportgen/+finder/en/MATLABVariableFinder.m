classdef MATLABVariableFinder< mlreportgen.finder.Finder
%mlreportgen.finder.MATLABVariableFinder Find MATLAB variables
%   finder = MATLABVariableFinder() creates a finder that finds
%   variables in the MATLAB base workspace. Use the finder's find
%   method to perform the search. By default the finder excludes
%   variables that relate to report generation such as
%   mlreportgen.report.Report objects and mlreportgen.dom.Paragraph
%   objects. Use the finder properties to specify search options.
%
%   finder = MATLABVariableFinder(container) creates a finder that finds
%   variables in the specified container. The container argument can be
%   one of the following values:
%       "MATLAB"                    - Find variables in the MATLAB base
%                                     workspace
%       "Global"                    - Find variables in the global
%                                     workspace
%       Name or path of a MAT file  - Find variables in the specified
%                                     MAT file
%
%   finder = MATLABVariableFinder(p1=v1,p2=v2,...) creates a
%   variable finder and sets its properties (p1, p2, ...) to the
%   specified values (v1, v2, ...).
%
%
%   MATLABVariableFinder properties:
%
%       Container                   - Workspace to search for variables
%       Name                        - Name of variable to search for
%       Regexp                      - Enable regular expression matching
%       IncludeReportVariables      - Whether to include variables related to report generation
%       Properties                  - Properties of variables to find
%
%   MATLABVariableFinder methods:
%
%       find    - Finds variables in specified container
%       hasNext - Determines whether the queue has a result
%       next    - Returns the next variable in the variable result queue
%
%   Example:
%
%         import mlreportgen.report.*
%         import mlreportgen.finder.*
%
%         % Create a MATLAB Report
%         rpt = Report("MATLABVariableFinder Example","pdf");
%
%         % Create some variables
%         x = 1:10;
%         y = sin(x);
%
%         % Find variables using MATLABVariableFinder
%         results = find(MATLABVariableFinder("MATLAB"));
%
%         % Append the results to the report
%         append(rpt,results);
%
%         % Close the report and open the viewer
%         close(rpt);
%         rptview(rpt);
%
%   See also mlreportgen.report.MATLABVariable, mlreportgen.finder.MATLABVariableResult

 
    %   Copyright 2021-2024 The MathWorks, Inc.

    methods
        function out=MATLABVariableFinder
        end

        function out=emptyResult(~) %#ok<STOUT>
        end

        function out=find(~) %#ok<STOUT>
            % results = find(finder) finds variables in the specified container
            %   This method returns the variables it finds represented by
            %   result objects of type
            %   mlreportgen.finder.MATLABVariableResult. You can add
            %   information about the variables to a report by adding
            %   the result objects to the report directly or by adding them
            %   to a reporter that you then add to a report.
            %
            %   See also mlreportgen.finder.MATLABVariableResult
        end

        function out=findImpl(~) %#ok<STOUT>
            %findImpl Populates the NodeList property of this finder with
            % MATLABVariableResult objects. Also sets the NodeCount
            % property.
        end

    end
    properties
        % IncludeReportVariables Whether to include variables related to report generation
        %   Whether to include variables related to report generation in
        %   the variable search. Report generation variables include any
        %   DOM or Report API object, such as mlreportgen.report.Report
        %   objects and mlreportgen.dom.Paragraph objects. Use this
        %   property to include only variables that are relevant to the
        %   report. Acceptable values are:
        %
        %       false   - (default) Do not include DOM or Report API
        %                 objects in the finder results
        %       true    - Include DOM and Report API
        %                 objects in the finder results
        IncludeReportVariables;

        % Name Name of variable to search for
        %   Name of the variable to search for, specified as a string or
        %   character vector. If the Regexp property is true, this value
        %   may contain a regular expression. If the regular expression
        %   matches mutliple variable names, all variables matching the
        %   expression are returned by the find method.
        Name;

        % Regexp Enable regular expression matching
        %    Flag to enable regular expression matching for the Name
        %    property. If this property is true, all variables matching the
        %    regular expression specified by the Name property are returned
        %    by the find method. If this property is false, the finder
        %    searches only for variables that match the Name property
        %    exactly.
        %    Acceptable values are:
        %
        %       false     - (default) Do not allow regular expression 
        %                   matching for the Name property.
        %       true      - Allow regular expression matching for the Name
        %                   property.
        %
        %    For example, to search the MATLAB base workspace for variables
        %    that start with "myVar", specify "Regexp", true, and "Name",
        %    "^myVar":
        %
        %       finder = mlreportgen.finder.MATLABVariableFinder(...
        %                Container="MATLAB", ...
        %                Regexp=true, ...
        %                Name="^myVar")
        Regexp;

    end
end
