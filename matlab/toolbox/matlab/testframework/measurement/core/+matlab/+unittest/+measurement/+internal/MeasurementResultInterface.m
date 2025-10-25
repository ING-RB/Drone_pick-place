classdef (Abstract,Hidden) MeasurementResultInterface < matlab.mixin.CustomDisplay
    % Measurement Result Interface
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2021 The MathWorks, Inc. 
   
    properties (SetAccess = private, Abstract)
        Name;
        Valid;
        Samples;
        TestActivity;
    end
    
    properties (SetAccess = private, Hidden, Abstract)
        Duration
    end
    
    methods(Hidden, Access = protected)
       function footerStr = getFooter(result)
            % getFooter - Override of the matlab.mixin.CustomDisplay hook method
            %   Displays a summary of the measurement results.
            
            import matlab.unittest.internal.diagnostics.indent;
            
            totals = getString(message('MATLAB:unittest:measurement:MeasurementResult:Totals'));
            
            validInvalid = ...
                getString(message('MATLAB:unittest:measurement:MeasurementResult:ValidInvalid', ...
                nnz([result.Valid]), ...
                nnz(~[result.Valid])));
            
            duration = getString(message('MATLAB:unittest:measurement:MeasurementResult:Duration', ...
                num2str(getTotalDuration(result))));
            
            indention = '   ';
            footerStr = sprintf('%s\n%s\n%s\n', totals, ...
                indent(validInvalid,indention), ...
                indent(duration, indention));
       end 
    end
    methods(Access = private)
       function totalDuration = getTotalDuration(result)
            totalDuration = sum(arrayfun(@(r) r.Duration, result(:)));
        end
    end
end