classdef NumericVectorReporter< mlreportgen.report.internal.variable.StringReporter
% NumericVectorReporter Reports on a variable whose value is a numeric
% vector.

     
    % Copyright 2018 The MathWorks, Inc.

    methods
        function out=NumericVectorReporter
            % this = NumericVectorReporter(reportOptions, varName, varValue)
            % creates a reporter for a numeric vector variable
            % varName/Value.
        end

        function out=getTextualContent(~) %#ok<STOUT>
            % Override the base class method to return the textual content. 
            % Get textual content by calling the base class method and then
            % normalize the content string. Normalizing the content string
            % is done to remove any unnecessary line breaks in the content
            % for a column vector.
        end

    end
end
