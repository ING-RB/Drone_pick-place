classdef requirementsSettings
%

%   Copyright 2019-2020 The MathWorks, Inc.

    methods (Static)
        
        function value = isDataDetectionOn()
            value = matlab.depfun.internal.requirementsSettings.dataDependency();
        end
        
        function setDataDetection(dataDetectionValue)
            matlab.depfun.internal.requirementsSettings.dataDependency(dataDetectionValue);
        end
      
    end
    
    methods (Static, Access=private)
        %Abstract away function that contains persistent variable for
        %simpler interface
        function dataDependencyValue = dataDependency(varargin)
            persistent dataDependencyOn
            
            if nargin == 1
                dataDependencyOn = varargin{1};
            end
            if isempty(dataDependencyOn)
                dataDependencyOn = true;
            end
            
            dataDependencyValue = dataDependencyOn;
        end 
    end
end

