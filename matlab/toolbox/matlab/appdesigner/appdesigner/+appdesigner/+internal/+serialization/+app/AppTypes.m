classdef AppTypes
    % AppTypes is a list of all supported AppTypes in App Designer
    % Use this central place to maintain AppTypes info on MATLAB side to
    % avoid typo.
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (Constant)
        % Standard app type
        StandardApp = 'Standard';
        
        % Responsive app type
        ResponsiveApp = 'Responsive';
        
        % Component app type
        UserComponentApp = 'CustomUIComponent';
    end
    
end