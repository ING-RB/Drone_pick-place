classdef (Hidden, SupportExtensionMethods) NumericMeasurementResult < matlab.unittest.measurement.MeasurementResult
    % NumericMeasurementResult - This class is undocumented.
    
    % Copyright 2018-2023 The MathWorks, Inc.
    
    methods
        function T = sampleSummary(result)
            %SAMPLESUMMARY - create a table of summary statistics from a MeasurementResult array.
            %
            %   T = SAMPLESUMMARY(R) creates a summary table from the
            %         Samples of a MeasurementResult array R that contains
            %         the following columns:
            %          - Name, SampleSize, Mean, StandardDeviation, Min, Median, Max
            %
            % See also matlab.unittest.measurement.MeasurementResult/samplefun.
            
            % split by labels, and columnize upfront so all data is in column format
            result = result.splitByLabels; 
            result = result(:);
            
            % Prepare Name column
            MeasurementName = cell(size(result));
            
            for i = 1: length(result)
                if result(i).NumLabels == 0
                    MeasurementName(i) = {categorical({result(i).Name})};
                else
                    MeasurementName(i) = {result(i).appendLabelToName(result(i).LabelList)};
                end
            end
            
            Name = vertcat(MeasurementName{:}); 
            
            [SampleSize, Sum, Var, Min, Median, Max] = samplefun(@runstats, result);
            % vectorize outside where possible
            StandardDeviation = sqrt(Var);
            Mean = Sum ./ SampleSize;
            
            T = table(Name, SampleSize, Mean, StandardDeviation, Min, Median, Max);  
            
            function [N, Sum, Var, Min, Median, Max] = runstats(X)
                N = length(X);
                if N == 0
                    [Sum, Var, Min, Median, Max] = deal(NaN);
                else
                    Sum    = sum(X);
                    Var    = var(X);
                    Min    = min(X);
                    Median = median(X);
                    Max    = max(X);
                end
            end
            
        end
    end
end
