classdef Verbosity < double
    % Verbosity - Specification of verbosity level
    %   The matlab.automation.Verbosity enumeration provides a means to specify
    %   the level of detail related to automation, such as running automated tests.
    
    % Copyright 2013-2022 The MathWorks, Inc.
    
    enumeration
        % None - No information
        None (0)
        
        % Terse - Minimal information
        Terse (1)
        
        % Concise - Moderate amount of information
        Concise (2)
        
        % Detailed - Some supplemental information
        Detailed (3)
        
        % Verbose - Lots of supplemental information
        Verbose (4)
    end
end

