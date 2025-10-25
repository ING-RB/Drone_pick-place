classdef OnlineFigureService < appdesigner.internal.application.figure.FigureService
    % OnlineFigureService Object to interact with the running figure when
    % in MATLAB Online
    
    % Copyright 2018 The MathWorks, Inc.
    
    methods
        function captureScreenshot(obj, appInstance, appFullFileName)                            
            % no op        
        end
        
        function bringToFront(obj, appInstance)
            % When in MO mode, Figure is running in main MATLAB Online
            % window, so bring that to front            
            connector.internal.webwindowmanager.instance().bringParentToFront; 
        end               
    end       
end