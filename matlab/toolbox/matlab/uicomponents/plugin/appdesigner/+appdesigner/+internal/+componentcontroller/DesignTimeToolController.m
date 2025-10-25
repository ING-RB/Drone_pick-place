classdef DesignTimeToolController < ...
        matlab.ui.internal.DesignTimeGBTComponentController & ...
        appdesigner.internal.componentcontroller.DesignTimeIconHandler
    
    % DesignTimeToolController - A tool controller class which consolidates
    % common logic between DesignTimeToggleToolController and
    % DesignTimePushToolController.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    methods
        function obj = DesignTimeToolController( varargin )
            obj = obj@matlab.ui.internal.DesignTimeGBTComponentController(varargin{:});
        end
    end
    
    methods (Access = 'protected')
        
        function handleDesignTimeEvent(obj, ~, event)
            % HANDLEDESIGNTIMEEVENT
            
            % Handle changes to the Icon property of the tool.
            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))
                
                propertyName = event.Data.PropertyName;
                
                if(strcmp(propertyName, 'Icon'))
                    
                    % Validate the inputted Icon file.
                    [fileNameWithExtension, validationStatus, imageRelativePath] = obj.validateImageFile(propertyName, event);
                
                    if validationStatus
                        iconValueToSet =  fileNameWithExtension;
                        viewmodel.internal.factory.ManagerFactoryProducer.setProperties(obj.ViewModel, {'ImageRelativePath', imageRelativePath});
                        % this is an event callback and we're adjusting the
                        % event data. Since it's called from handleEvent,
                        % it's a client event.
                        obj.handleComponentDynamicDesignTimeProperties(struct('ImageRelativePath', imageRelativePath), true);
                    
                    
                    
                        % Setting the property in this way ensures that the
                        % property is added to the client's undo/redo stack.
                        setServerSideProperty(obj, ...
                            obj.Model, ...
                            propertyName, ...
                            iconValueToSet, ...
                            event.Data.CommandId...
                            );
                        
                        % Set the Icon property then send the property set
                        % information to the client.
                        obj.setProperty('Icon');
                        obj.triggerSetIcon();
                    end
                end
            end
        end
        
        function excludedPropertyNames = getExcludedPropertyNamesForView(obj)
            % GETEXCLUDEDPROPERTYNAMESFORVIEW - Hook for subclasses to
            % provide a list of property names that needs to be excluded
            % from the properties sent to the view.  Examples include (1)
            % Children, Parent, are not needed by the view, and (2) Position,
            % InnerPosition, OuterPosition are not updated by the view and
            % are excluded so their peer node values don't become stale.
            
            % IconView and CDataView MUST be excluded from the view to
            % prevent build failures. These properties are exluded because
            % they are added by the PropertyManagementService but not
            % properties of the run-time component. The view properties
            % (IconView and CDataView) must have different names from the
            % model properties (Icon and CData) to avoid sending the raw
            % image data to the view - g2172712
            excludedPropertyNames = {
                'IconView';
                'CDataView';
                };
            
            excludedPropertyNames = [excludedPropertyNames; ...
                getExcludedPropertyNamesForView@matlab.ui.internal.DesignTimeGBTComponentController(obj); ...
                ];
        end
    end
end