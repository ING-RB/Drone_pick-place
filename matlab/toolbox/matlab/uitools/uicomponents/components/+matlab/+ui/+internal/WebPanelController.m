% WEBPANELCONTROLLER Web-based controller for UIPanel.
classdef WebPanelController < matlab.ui.internal.WebUIContainerController
    %

    %   Copyright 2014-2023 The MathWorks, Inc.

    properties(Access = 'protected')
        scrollableBehavior
    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = WebPanelController( model, varargin  )
            obj = obj@matlab.ui.internal.WebUIContainerController( model, varargin{:} );
            obj.scrollableBehavior = matlab.ui.internal.componentframework.services.optional.ScrollableBehaviorAddOn(obj.PropertyManagementService, obj.EventHandlingService);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      newFontSize
        %
        %  Description: Custom method to set newFontSize.
        %
        %  Outputs:     newFontSize struct-> on the Web Panel peernode
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newFontSize = updateFontSize( obj )
            newFontSize = obj.Model.FontSize;
            % using try catch as this is special case for the charts
            % as charts does not have the FontUnits property which need to be
            % ignored, need to investigate and come up with better option of
            % using the WebPanelController for the charts
            try
                value = struct('FontSize', obj.Model.FontSize, 'FontUnits', obj.Model.FontUnits);
                newFontSize = value;
            catch e 

            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateFontName
        %
        %  Description: Custom method to set newFontName. Handles
        %  fixedwidth font
        %
        %  Outputs:     newFontName, fontName ready for the view
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newFontName = updateFontName( obj )
            newFontName = matlab.ui.internal.FontUtils.getFontForView(obj.Model.FontName);
        end

        function newBorderVisibility = updateBorderVisibility( obj )
            value = obj.Model.BorderType;
            if(isequal(value, 'none'))
                value = false;
            else
                value = true;
            end
            newBorderVisibility = value;
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateScrollTarget
        %
        %  Description: Converts the ScrollTarget property to a view-compatible value
        %
        %  Outputs:     Value to be set on the view model
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function result = updateScrollTarget( obj )
            result = obj.scrollableBehavior.updateScrollTarget( obj.Model );
        end

        function className = getViewModelType(obj, ~)
            if obj.Model.isInAppBuildingFigure()
                className = 'matlab.ui.container.Panel';
            else
                className = 'matlab.ui.container.LegacyPanel';
            end
        end
    end

    methods( Access = 'protected' )

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      defineViewProperties
        %
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, this is the method the "Controller"
        %               layer uses to define which properties will be consumed by
        %               the web-based user interface.
        %  Inputs:      None
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineViewProperties( obj )
            defineViewProperties@matlab.ui.internal.WebUIContainerController( obj );

            % Add model properties for view specific to the panel

            %Properties needs no mapping/updates before updating to view
            obj.PropertyManagementService.defineViewProperty( 'Title' );
            obj.PropertyManagementService.defineViewProperty( 'TitlePosition' );
            obj.PropertyManagementService.defineViewProperty( 'Visible' );
            obj.PropertyManagementService.defineViewProperty( 'ForegroundColor' );
            obj.PropertyManagementService.defineViewProperty( 'FontAngle' );
            obj.PropertyManagementService.defineViewProperty( 'FontName' );
            obj.PropertyManagementService.defineViewProperty( 'FontWeight' );
            obj.PropertyManagementService.defineViewProperty( 'AutoResizeChildren' );
            obj.PropertyManagementService.defineViewProperty( 'Tooltip' );
            obj.PropertyManagementService.defineViewProperty( 'Enable' );
            obj.PropertyManagementService.defineViewProperty( 'HighlightColor' );
            obj.PropertyManagementService.defineViewProperty( 'BorderWidth' );
            obj.PropertyManagementService.defineViewProperty( 'EnableLegacyPadding' );
            obj.PropertyManagementService.defineViewProperty( 'BorderColor' );

            %Properties needs mapping/updates before updating to view
            obj.PropertyManagementService.defineViewProperty( 'BorderType' );
            obj.PropertyManagementService.defineViewProperty( 'FontSize' );
            obj.PropertyManagementService.defineViewProperty( 'FontUnits' );
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      definePropertyDependencies
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, this is the method the "Controller"
        %               layer uses to establish property dependencies between
        %               a property (or set of properties) defined by the "Model"
        %               layer and dependent "View" layer property.
        %  Inputs:      None
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function definePropertyDependencies( obj )
            definePropertyDependencies@matlab.ui.internal.WebUIContainerController(obj);
            obj.PropertyManagementService.definePropertyDependency("FontUnits", "FontSize");
            obj.PropertyManagementService.definePropertyDependency("BorderType","BorderVisibility");
        end

    	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      defineRequireUpdateProperties
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, this is the method the "Controller"
        %               layer uses to establish property which needs updates
        %               before updating them to view.
        %  Inputs:      None
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineRequireUpdateProperties( obj )
            obj.PropertyManagementService.defineRequireUpdateProperty("FontSize");
            obj.PropertyManagementService.defineRequireUpdateProperty("FontName");
        end

        function handleEvent( obj, src, event )
            if( obj.EventHandlingService.isClientEvent( event ) )

                eventStructure = obj.EventHandlingService.getEventStructure( event );
                handled = obj.scrollableBehavior.handleClientScrollEvent( src, eventStructure, obj.Model );

                if (~handled)
                    % Now, defer to the base class for common event processing
                    handleEvent@matlab.ui.internal.WebUIContainerController( obj, src, event );
                end
            end
        end
    end

end
