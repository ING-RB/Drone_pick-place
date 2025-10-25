classdef NullCollector < matlab.unittest.internal.plugins.CodeCoverageCollectorInterface
    %

    % Copyright 2021-2023 The MathWorks, Inc.
    properties (SetAccess=private)
        % Collecting - Boolean indicating whether the collector is active.
        %   The Collecting property is a Boolean indicating whether this instance
        %   is currently collecting coverage.
        Collecting
        
        % Results - Code coverage collection results.
        %   The Results property is a structure which contains the code coverage
        %   collection results data.
        Results
    end
    
    methods 
        % start - Start collecting code coverage.
        function start(~)
        end
        
        % stop - Stop collecting code coverage.
        function stop(~)
        end
        
        % clearResults - Clear the code coverage collection results.
        function clearResults(~)
        end
        
        function c = NullCollector()
            c.Collecting = false;
        end
        
        function r = get.Results(~)
            r = struct('StaticData', struct.empty,'RuntimeData', 0);
        end
    end
    
end
