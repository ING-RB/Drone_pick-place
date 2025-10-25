classdef FigureService < handle
    % FigureService
    %
    % An abstraction for interacting with a running app's figure    
    
    % Copyright 2018 The MathWorks, Inc.
    
    methods(Abstract)
        % Tells the service to capture a screenshot of the running App, and
        % save it to the given file name
        captureScreenshot(obj, appInstance, appFullFileName)                            
        
        % Tell the service to bring the running app to front
        bringToFront(obj, appInstance)                        
    end
    
end