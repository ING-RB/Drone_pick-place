classdef DesignTimeTabController < ...
        matlab.ui.internal.WebTabController & ...
        matlab.ui.internal.DesignTimeGbtParentingController
    
    % DesignTimeTabController  A tab controller class which encapsulates the
    % design-time specific data and behavior and establishes the gateway
    % between the Model and the View.
    
    % Copyright 2014-2021 The MathWorks, Inc.
    
    methods
        
        function obj = DesignTimeTabController( model, parentController, proxyView, adapter )
            % CONSTRUCTOR
            
            % Input verification
            narginchk( 4, 4 );
            
            % Construct the run-time controller first
            obj = obj@matlab.ui.internal.WebTabController( model, ...
                parentController, ...
                proxyView );
            
            % Now, construct the client-driven controller
            obj = obj@matlab.ui.internal.DesignTimeGbtParentingController(model, parentController, proxyView, adapter);
        end        
    end
    
    methods ( Access=protected)
        
        function updateToPositionBehavior(obj, src, eventData)
            obj.positionBehavior.handleClientPositionEvent( src, eventData, obj.Model );
        end
        
        function excludedPropertyNames = getExcludedPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view
            %
            % Examples:
            % - Children, Parent, are not needed by the view
            % - Position, InnerPosition, OuterPosition are not updated by
            % the view and are excluded so their peer node values don't
            % become stale
            
            excludedPropertyNames = {'Enable'; 'Position'; ...
                'TooltipString'; 'UserData'; 'FontAngle'; 'FontName'; 'FontWeight'};
            
            excludedPropertyNames = [excludedPropertyNames; ...
                getExcludedPropertyNamesForView@matlab.ui.internal.DesignTimeGbtParentingController(obj); ...
                ];
        end
        
        function updatePositionWithSizeLocationPropertyChanges(~, ~)
            % Override the method since Position property is read-only for
            % Tab
            
            % Note: Location and size related properties can change
            % on the client and come through this switch statement
            % (Location, OuterLocation,Size,OuterSize) but no action
            % is taken because the server cannot update the Position
            % property of the tab because its read-only.  The parent
            % tabGroup will take care of the tab size
            
            % no-op here
        end
        
        function handleDesignTimePropertyChanged(obj, peerNode, valuesStruct)
			% Handle property updates from the client
			
			updatedProperty = valuesStruct.key;
			
            switch ( updatedProperty )
                
                case 'Position'
                    % DO NOTHING
                    % b/c Position on the Tab is a read-only property
                otherwise
                    % call base class to handle it
                    handleDesignTimePropertyChanged@matlab.ui.internal.DesignTimeGBTComponentController(obj, peerNode, valuesStruct);                    
            end            
        end

        function additionalPropertyNamesForView = getAdditionalPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be sent to the view for loading in addition to the 
            % ones pushed to the view defined by PropertyManagementService
            %
            % Example:
            % 1) Callback function properties
            % 2) FontUnits required by client side

            additionalPropertyNamesForView = {'ButtonDownFcn'; 'SizeChangedFcn'};

            additionalPropertyNamesForView = [additionalPropertyNamesForView; ...
                getAdditionalPropertyNamesForView@matlab.ui.internal.DesignTimeGBTComponentController(obj); ...
                ];
        end
    end

    methods

        function adjustedProps = adjustParsedCodegenPropertiesForAppLoad(obj, parsedProperties)
            % Provides an opportunity for controllers to modify what was
            % considered dirty, parsed from generated code.

            adjustedProps = adjustParsedCodegenPropertiesForAppLoad@appdesigner.internal.controller.DesignTimeController(obj, parsedProperties);

            % always consider uipanel.Title, the default is different between
            % designtime and runtime defaults.
            adjustedProps = [adjustedProps, {'Title'}];
        end

        function viewPvPairs = getPositionPropertiesForView(obj, propertyNames)
            % Gets all properties for view based related to Size,
            % Location, etc...
            
            positionViewPvPairs = getPositionPropertiesForView@matlab.ui.internal.DesignTimeGBTComponentController(obj, propertyNames);
            
            positionPropertyNames = positionViewPvPairs(1:2:end);
            positionPropertyValues = positionViewPvPairs(2:2:end);
            
            % Remove 'Position' property since it is read-only
            % Remove 'OuterLocation' for Tab doesn't have it
            excludedPositionProperties = {'Position'};
            
            viewPvPairs = {};
            for idx = 1:length(positionPropertyNames)
                propertyName = positionPropertyNames{idx};
                if ~any(strcmp(propertyName, excludedPositionProperties))
                    viewPvPairs = [viewPvPairs, {propertyName, positionPropertyValues{idx}}];
                end
            end
        end
    end
    
end