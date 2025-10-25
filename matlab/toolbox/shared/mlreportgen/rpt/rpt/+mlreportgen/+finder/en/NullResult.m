classdef NullResult< mlreportgen.finder.Result
    methods
        function out=NullResult
        end

        function out=getDefaultSummaryProperties(~) %#ok<STOUT>
            % Returns a string array of properties to report by default for 
            % the result object.
        end

        function out=getDefaultSummaryTableTitle(~) %#ok<STOUT>
            % Returns the default title used by the SummaryTable reporter
        end

        function out=getPropertyValues(~) %#ok<STOUT>
            % Returns the values of the properties specified in propNames for 
            % the result's object and returns the values in propVals as a 
            % horizontal cell array
        end

        function out=getReporter(~) %#ok<STOUT>
        end

    end
    properties
        Object;

        Tag;

    end
end

 
    %   Copyright 2017-2022 The MathWorks, Inc.

