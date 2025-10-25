classdef SummaryTableBase< handle
%mlreportgen.report.SummaryTableBase  A base class for MATLAB and
%Simulink Summary Table

 
    %   Copyright 2021 The MathWorks, Inc.

    methods
        function out=SummaryTableBase
        end

        function out=getSingleSummaryTableData(~) %#ok<STOUT>
            % Returns the title, reported properties, and property values
            % to use to create a single summary table out of the results
            % specified. Title is a string, props is an array of strings,
            % and content is a cell array of property values.
        end

    end
end
