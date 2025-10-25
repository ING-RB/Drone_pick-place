classdef (Sealed, ConstructOnLoad=true) HTML < ...
        matlab.ui.control.internal.model.ComponentModel & ...
        matlab.ui.control.internal.model.mixin.InternalHTML & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent& ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.FocusableComponent

    % Copyright 2019-2024 The MathWorks, Inc.

    properties(Dependent)
        Data;
    end

    properties(Dependent, AbortSet)
        HTMLSource;
    end

    properties(Access = {...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.controller.AbstractController})
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        PrivateData = [];
        PrivateHTMLSource = '';

        % A Cell array of eventName, eventData pairs that should be sent
        % {
        %   {eventName, eventData}, ...
        %   {eventName, eventData}, ...
        %   {eventName, eventData}, ...
        % }
        %
        % This is sent only when an update traversal happens, so this is
        % cached in the model and used by the controller
        PrivateEventsToHTMLSource = {};
    end

    properties(NonCopyable, Dependent, AbortSet)
        DataChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
        HTMLEventReceivedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end

    properties(NonCopyable, Access = 'private')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateDataChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
        PrivateHTMLEventReceivedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end

    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})
        DataChanged
        HTMLEventReceived
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = HTML(varargin)
            obj.Type = 'uihtml';

            defaultSize = [100 100];
            obj.PrivateInnerPosition(3:4) = defaultSize;
            obj.PrivateOuterPosition(3:4) = defaultSize;

            parsePVPairs(obj,  varargin{:});

            obj.attachCallbackToEvent('DataChanged', 'PrivateDataChangedFcn');
            obj.attachCallbackToEvent('HTMLEventReceived', 'PrivateHTMLEventReceivedFcn');
        end

        function sendEventToHTMLSource(obj, eventName, eventData)
            %SENDEVENTTOHTMLSOURCE - Sends an event to the HTML Source page
            arguments
                obj
                eventName (1,:) {mustBeText}
                % 'eventData' is optional
                eventData = [];
            end

            obj.PrivateEventsToHTMLSource = [obj.PrivateEventsToHTMLSource, {{eventName, eventData}}];
            obj.markPropertiesDirty({'PrivateEventsToHTMLSource'});
        end

        function set.HTMLSource(obj, newValue)
            % Error Checking

            % Basic data type
            try
                newValue = matlab.ui.control.internal.model.PropertyHandling.validateText(newValue);
            catch ME
                messageObj = message('MATLAB:ui:components:invalidTextValue', ...
                    'HTMLSource');

                % MnemonicField is last section of error id
                mnemonicField = 'invalidHTMLSource';

                % Use string from object
                messageText = getString(messageObj);

                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
            end

            newValue = obj.validateInput(newValue);

            % Update properties, send to view
            obj.PrivateHTMLSource = newValue;
            markPropertiesDirty(obj, {'HTMLSource'});
        end

        function value = get.HTMLSource(obj)
            value = obj.PrivateHTMLSource;
        end

        function set.Data(obj, newData)
            % No Error Checking, Data can be anything

            % Property Setting
            obj.PrivateData = newData;

            % Update View
            markPropertiesDirty(obj, {'Data'});
        end

        function value = get.Data(obj)
            value = obj.PrivateData;
        end

        function set.DataChangedFcn(obj, newValue)
            % Property Setting
            obj.PrivateDataChangedFcn = newValue;

            % Dirty
            obj.markPropertiesDirty({'DataChangedFcn'});
        end

        function value = get.DataChangedFcn(obj)
            value = obj.PrivateDataChangedFcn;
        end

          function set.HTMLEventReceivedFcn(obj, newValue)
            % Property Setting
            obj.PrivateHTMLEventReceivedFcn = newValue;

            % Dirty
            obj.markPropertiesDirty({'HTMLEventReceivedFcn'});
        end

        function value = get.HTMLEventReceivedFcn(obj)
            value = obj.PrivateHTMLEventReceivedFcn;
        end
    end

    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)
        function doUpdate(obj)
            % DOUPDATE - This function overrides
            % default no-op functionality provided by UIComponent.  For
            % MATLAB-implemented components, properties changed in the
            % Model must explicitly be flushed to the controller.

            doUpdate@matlab.ui.control.internal.model.ComponentModel(obj);
            if ~isempty(obj.Controller)
                obj.Controller.flushQueuedEventsToView();
            end
        end

        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.

            names = { ...
                % TODO: consider if HTML belows in the disp
                'HTMLSource',...
                'Data',...
                ...Callbacks
                'DataChangedFcn'  ...
                'HTMLEventReceivedFcn'  ...
                };
        end

        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = obj.HTMLSource;
        end

        function traverse = applyThemeValues(obj, themeObj)
           traverse = applyThemeValues@matlab.ui.control.internal.model.mixin.InternalHTML(obj, themeObj);
        end
    end
end




