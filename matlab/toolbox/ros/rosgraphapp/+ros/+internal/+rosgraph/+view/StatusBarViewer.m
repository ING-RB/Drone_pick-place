classdef StatusBarViewer < handle
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.
    
    properties(Access = {?matlab.unittest.TestCase, ?ros.internal.rosgraph.view.AppView})

        DomainIdLabel
        LastUpdatedLabel
    end
    
    properties (Constant, Access = ?matlab.unittest.TestCase)
        %% Tags
        TagStatusBar = "statusBar"
        TagStatusDomainIdLabel = "DomainIdLabel"
        TagLastUpdatedLabel = "LastUpdatedLabel"

        %% Catalogs
        DescriptionDomainIdLabel = getString(message("ros:rosgraphapp:view:DescriptionDomainIdLabel"))
        DescriptionLastUpdatedLabel = getString(message("ros:rosgraphapp:view:DescriptionLastUpdatedLabel"))
    end

    methods
        function obj = StatusBarViewer(appContainer)
            
           createStatusBar(obj,appContainer)
        end
        
        function createStatusBar(obj, appContainer)
           
           statusBar = matlab.ui.internal.statusbar.StatusBar();
           statusBar.Tag = obj.TagStatusBar;
           appContainer.add(statusBar);

           obj.DomainIdLabel = matlab.ui.internal.statusbar.StatusLabel();
           obj.DomainIdLabel.Tag = obj.TagStatusDomainIdLabel;
           obj.DomainIdLabel.Description = obj.DescriptionDomainIdLabel;
           
           obj.LastUpdatedLabel = matlab.ui.internal.statusbar.StatusLabel();
           obj.LastUpdatedLabel.Tag = obj.TagLastUpdatedLabel;
           obj.LastUpdatedLabel.Description = obj.DescriptionLastUpdatedLabel;

           statusBar.add(obj.DomainIdLabel);
           statusBar.add(obj.LastUpdatedLabel);
        end

        function updateDomainId(obj, domainId)
            
            obj.DomainIdLabel.Text = "DOMAIN ID: " + domainId;
        end

        function updateLastRefrestedTime(obj, timeStamp)
            
            obj.LastUpdatedLabel.Text = "Updated at : " + timeStamp;
        end
    end
        
end

function makeCallback(fcn, varargin)
%makeCallback Evaluate specified function with arguments if not empty

    if ~isempty(fcn)
        feval(fcn, varargin{:})
    end
end