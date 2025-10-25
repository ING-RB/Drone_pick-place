classdef DesignTimeToggleToolController < ...
        appdesigner.internal.componentcontroller.DesignTimeToolController & ...
        matlab.ui.internal.controller.WebToggleToolController     
    
    % DesignTimeToggleToolController - A toggle tool controller class which
    % encapsulates the design-time specific behaviour and establishes the
    % gateway between the Model and the View
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods
        function obj = DesignTimeToggleToolController( model, parentController, proxyView, adapter)
            % CONSTRUCTOR
            
            % Input verification
            narginchk(3, 4);
            
            % Construct the run-time controller
            obj = obj@matlab.ui.internal.controller.WebToggleToolController(model, parentController, proxyView);
            
            % Construct the appdesigner base class controllers
            obj = obj@appdesigner.internal.componentcontroller.DesignTimeToolController(model, parentController, proxyView, adapter);

            % Update all properties once the proxy view has been setup.
            % This ensures that the run-time component updates the displayed
            % image and pushes the IconView property to the client.
            if ~isempty(obj.ViewModel)
                obj.triggerUpdatesOnDependentViewProperties();
            end
        end
        
        function triggerSetIcon(obj)
            obj.EventHandlingService.setProperty('Icon', obj.Model.Icon);
        end
    end
        
    methods (Access = 'protected')
      
        function additionalPropertyNamesForView = getAdditionalPropertyNamesForView(obj)
            % GETADDITIONALPROPERTYNAMESFORVIEW - Hook for subclasses to
            % provide a list of property names that need to be sent to the
            % view for loading in addition to the ones pushed to the view
            % defined by PropertyManagementService.  Examples of such
            % properties include, (1) Callback function properties, and (2)
            % FontUnits required by the client.
            
            % The ClickedCallback, OffCallback, and OnCallback are not
            % pushed to the view by PropertyManagementService and must be
            % defined here.
            additionalPropertyNamesForView = {
                'ClickedCallback';
                'OffCallback';
                'OnCallback';
                'Icon'
                };
            
            additionalPropertyNamesForView = [...
                additionalPropertyNamesForView; ...
                getAdditionalPropertyNamesForView@matlab.ui.internal.DesignTimeGBTComponentController(obj); ...
                ];
        end
    end
end