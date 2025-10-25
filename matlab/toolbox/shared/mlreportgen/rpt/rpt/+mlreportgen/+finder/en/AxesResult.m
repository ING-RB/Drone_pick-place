classdef AxesResult< mlreportgen.finder.Result
%mlreportgen.finder.AxesResult Container for an AxesFinder result
%   This class contains an axes handle representing an
%   axes. The find method of the mlreportgen.finder.AxesFinder
%   class creates instances of this class for the axes it finds. You
%   do not need to create AxesResult instances yourself.
%
%   Add an AxesResult object directly to a report, or use the
%   getReporter method to customize the Axes reporter that is
%   used to report on information contained in this result.
%
%   AxesResult properties:
%       Object              - axes handle
%       Tag                 - Tag to associate with result
%
%   AxesResult methods:
%       getReporter         - Returns reporter for this axes
%
%   See also mlreportgen.finder.AxesFinder,
%   mlreportgen.report.Axes

 
    %   Copyright 2021 The MathWorks, Inc.

    methods
        function out=getDefaultSummaryProperties(~) %#ok<STOUT>
            % properties = getDefaultSummaryProperties(axesResult)
            % returns a string array of default properties to be reported
            % by the mlreportgen.report.SummaryTable class
            % when summarizing axes result objects. The default
            % properties reported are:
            %   - Title
            %   - Tag
            %   - XLim
            %   - YLim
            %   - Units
            %
            % See also mlreportgen.report.SummaryTable
        end

        function out=getDefaultSummaryTableTitle(~) %#ok<STOUT>
            % title = getDefaultSummaryTableTitle(axessResult) returns the
            % default summary table title used by the
            % mlreportgen.report.SummaryTable class if no title is
            % specified when summarizing axes results.
            %
            % See also mlreportgen.report.SummaryTable
        end

        function out=getPresenter(~) %#ok<STOUT>
        end

        function out=getPropertyValues(~) %#ok<STOUT>
            % propValues = getPropertyValues(axesResult, propertyNames)
            % gets the values of the properties specified in propertyNames
            % for the axes result's Object. The property values are
            % returned in propValues as a horizontal cell array. If
            % propertyNames contains any invalid properties, the
            % corresponding value in the cell array is "N/A". propValues
            % can contain strings or arrays of strings. All valid
            % properties of an axes are supported.
            %
            % See also mlreportgen.report.SummaryTable
        end

        function out=getReporter(~) %#ok<STOUT>
            % reporter = getReporter(axesResult) returns a reporter
            % that is used to include a snapshot of an axes in a
            % report.
            % See the Axes reporter help for more information on
            % how to customize the reporter.
            %
            % See also mlreportgen.report.Axes
        end

        function out=getReporterLinkTargetID(~) %#ok<STOUT>
            % id = getReporterLinkTargetID(axesResult) returns the link
            % target ID of the reporter obtained by the axes result's
            % getReporter method. If the reporter's LinkTarget property is
            % empty, this method uses the default link target ID generated
            % by the reporter. Otherwise, this method returns the
            % link target ID in the reporter's LinkTarget property.
        end

    end
    properties
        % Object axes handle that represents the axes
        %   This read-only property contains the axes handle
        Object;

        %Tag Result identifier
        %   This property allows you to attach additional information to
        %   a result. You can set it to any value that meets your
        %   requirements.
        Tag;

    end
end
