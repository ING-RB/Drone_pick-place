classdef Result< matlab.mixin.SetGet & matlab.mixin.Heterogeneous
%Result Abstract result class
%   Class of finder result objects. These objects can be added to a report or reporter to
%   generate a formatted result.

 
    % Copyright 2017-2022 MathWorks, Inc.

    methods
        function out=Result
        end

        function out=formatDOMPropertyValue(~) %#ok<STOUT>
            % Helper function to prepare DOM objects to be returned by the
            % getPropertyValues method. If the ConvertToString option is
            % false, this method returns the input domObj with the StyleName
            % modified so that the object can be used by the SummaryTable
            % reporter.
            % If the ConvertToString option is true, this method returns
            % the string content contained by the input domObj.
        end

        function out=getDefaultScalarElement(~) %#ok<STOUT>
        end

        function out=getReporterLinkTargetID(~) %#ok<STOUT>
            % Returns the default link target ID for the reporter returned 
            % by the result's getReporter method.
        end

    end
    methods (Abstract)
        % Returns a string array of properties to report by default for 
        % the result object.
        getDefaultSummaryProperties;

        % Returns the default title used by the SummaryTable reporter
        getDefaultSummaryTableTitle;

        % Returns the values of the properties specified in propNames for 
        % the result's object and returns the values in propVals as a 
        % horizontal cell array
        getPropertyValues;

        getReporter;

    end
    properties
        % Object Handle of result object
        Object;

        SummaryTableListStyle;

        Tag;

    end
end
