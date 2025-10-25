classdef WebToolMixinController < matlab.ui.internal.componentframework.WebContainerController
    % WebToolMixinController Web-based controller for shared functionality
    % in matlab.ui.container.toolbar.PushTool and
    % matlab.ui.container.toolbar.ToggleTool objects.

    %   Copyright 2020-2022 The MathWorks, Inc.

    properties

    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = WebToolMixinController(model, varargin )
            %WebToolMixinController Construct an instance of this class
            obj = obj@matlab.ui.internal.componentframework.WebContainerController( model, varargin{:} );
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      validateToolIcon
        %
        %  Description: Validate the tool icon using IconUtils API
        %
        %  Outputs:     validatedIcon, iconType
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [validatedIcon, iconType] = validateToolIcon( obj, iconValue )
            validatedIcon = '';
            iconType = '';
            try
                [validatedIcon, iconType] = matlab.ui.internal.IconUtils.validateIcon(iconValue);
                % Throw error for 'preset' image type since its not supported
                % for Image component
                if strcmp(iconType, 'preset')
                    % Throw error on invalid ImageSource
                    throwAsCaller(MException(message('MATLAB:hg:gbtdatatypes:Icon:invalidIcon')));
                end
            catch ex
                w = warning('off', 'backtrace');

                % MnemonicField is last section of error id
                mnemonicField = ex.identifier(regexp(ex.identifier,'\w*$'):end);
                % Get messageText from exception
                messageText = ex.message;

                if strcmp(mnemonicField, 'invalidIconNotInPath') || strcmp(mnemonicField, 'cannotReadIconFile') || strcmp(mnemonicField, 'unableToWriteCData')
                    % Warn and proceed when Icon file cannot be read.
                    % This is done, so that the app can continue working when
                    % it is loaded and when the Image file is invalid or doesn't
                    % exist
                    matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj, mnemonicField, messageText);
                else
                    % Get identifier specific for Icon
                    if strcmp(mnemonicField, 'invalidIconFile')
                        messageText = getString(message('MATLAB:hg:gbtdatatypes:Icon:invalidIcon'));
                        mnemonicField = 'invalidIcon';
                    end
                    % Create and throw exception for errors related to
                    % invalidIconFormat, cannotReadIconFile, and any other
                    % errors related to Icon
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                    throwAsCaller(exceptionObject);
                end
                % Restore warning state
                warning(w)
            end

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      getCroppedCData
        %
        %  Description: Custom method to crop CData to 16x16.
        %
        %  Outputs:     croppedCData
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function croppedCData = getCroppedCData( obj )
            % Crop CData to the center 16x16x3
            [cdataX, cdataY, cdataZ] = size(obj.Model.CData);
            newXRange = 1:cdataX;
            newYRange = 1:cdataY;
            if cdataX > 16
                diffX = cdataX - 16;
                newXFromLeft = ceil(diffX / 2);
                newXFromRight = diffX - newXFromLeft;
                newXRange = newXFromLeft+1:cdataX-newXFromRight; % Add 1 for 1-indexing
            end
            if cdataY > 16
                diffY = cdataY - 16;
                newYFromTop = ceil(diffY / 2);
                newYFromBottom = diffY - newYFromTop;
                newYRange = newYFromTop+1:cdataY-newYFromBottom; % Add 1 for 1-indexing
            end
            croppedCData = obj.Model.CData(newXRange,newYRange,:);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateCDataView
        %
        %  Description: Custom method to set new CData.
        %
        %  Outputs:     uri to the newCData -> on the Tool peernode
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newCData = updateCDataView( obj )
            newCData = '';
            if(~isempty(obj.Model.CData))
                % If Icon is currently nonempty, issue warning that Icon takes priority
                if (~isempty(obj.Model.Icon))
                    w = warning('backtrace', 'off');
                    warning(message('MATLAB:uitoolmixin:IconVsCDataPrioritization'));
                    warning(w);
                end

                try
                    % Crop CData to the center 16x16x3
                    newCDataForView = obj.getCroppedCData();
                    newCData = matlab.ui.internal.IconUtils.getURLFromCData(newCDataForView);
                catch ex
                    % Create and throw warning
                    messageText = getString(message('MATLAB:ui:components:UnexpectedErrorInImageSourceOrIcon', 'CData'));
                    matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj, 'UnexpectedErrorInImageSourceOrIcon', ...
                        messageText, ':\n%s', ex.getReport());
                end
            end

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateIconView
        %
        %  Description: Custom method to set new Icon.
        %
        %  Outputs:     uri or url to the newIcon -> on the Tool peernode
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newIcon = updateIconView( obj )
            newIcon = '';
            if(~isempty(obj.Model.Icon))
                % If CData is currently nonempty, issue warning that Icon takes priority
                if (~isempty(obj.Model.CData))
                    w = warning('backtrace', 'off');
                    warning(message('MATLAB:uitoolmixin:IconVsCDataPrioritization'));
                    warning(w);
                end

                [validatedIcon, iconType] = obj.validateToolIcon(obj.Model.Icon);
                try
                    % Get icon URL
                    newIcon = matlab.ui.internal.IconUtils.getIconForView(validatedIcon, iconType);
                catch ex
                    % Create and throw warning
                    messageText = getString(message('MATLAB:ui:components:UnexpectedErrorInImageSourceOrIcon', 'Icon'));
                    matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj, 'UnexpectedErrorInImageSourceOrIcon', ...
                        messageText, ':\n%s', ex.getReport());
                end
            end

        end

    end

    methods (Access = 'protected')

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      postAdd
        %
        %  Description: Custom method for controllers which gets invoked after the
        %               addition of the web component into the view hierarchy.
        %
        %  Inputs :     None.
        %  Outputs:     None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function postAdd( obj )

            % Attach a listener for events
            obj.EventHandlingService.attachEventListener( @obj.handleEvent );

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       handleEvent
        %
        %  Description:  handle the ToolClicked event from the client
        %
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function handleEvent( obj, src, event )

            if( obj.EventHandlingService.isClientEvent( event ) )

                eventStructure = obj.EventHandlingService.getEventStructure( event );
                switch ( eventStructure.Name )
                    case 'ToolClicked'
                        obj.fireActionEvent();
                    otherwise
                        % Now, defer to the base class for common event processing
                        handleEvent@matlab.ui.internal.componentframework.WebComponentController( obj, src, event );
                end

            end

        end


        % Call a custom c++ method to fire action callback in GBT event chain
        function fireActionEvent(obj)
            obj.Model.handleActionEventFromClient();
        end

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

            % Add model properties concerning the view common to all tools
            
            %Properties needs no mapping/updates before updating to view
            obj.PropertyManagementService.defineViewProperty( "Enable" );
            obj.PropertyManagementService.defineViewProperty( "Visible" );
            obj.PropertyManagementService.defineViewProperty( "Separator" );
            obj.PropertyManagementService.defineViewProperty( "Tooltip" );

            obj.PropertyManagementService.defineViewProperty( 'ContextMenu' );

            %Properties needs mapping/updates before updating to view
            obj.PropertyManagementService.defineViewProperty( "Icon" );
            obj.PropertyManagementService.defineViewProperty( "CData" );
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
            obj.PropertyManagementService.definePropertyDependency("Icon", "IconView");
            obj.PropertyManagementService.definePropertyDependency("CData", "CDataView");
        end
    end
end

