classdef (Sealed, ConstructOnLoad=true) TextArea < ...
        matlab.ui.control.internal.model.ComponentModel & ...
        matlab.ui.control.internal.model.mixin.EditableComponent & ...
        matlab.ui.control.internal.model.mixin.HorizontallyAlignableComponent & ...
        matlab.ui.control.internal.model.mixin.WordWrapComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.BackgroundColorableComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent& ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent & ...
        matlab.ui.control.internal.model.mixin.PlaceholderComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.FocusableComponent
    %

    % Do not remove above white space
    % Copyright 2013-2023 The MathWorks, Inc.

    properties(Dependent, AbortSet)
        Value = {''};
    end

    properties(NonCopyable, Dependent, AbortSet)
        ValueChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];

        ValueChangingFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end

    properties(Access = {?appdesservices.internal.interfaces.model.AbstractModel})
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateValue = {''};
    end

    properties(NonCopyable, Access = 'private')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateValueChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];

        PrivateValueChangingFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end

    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})
        ValueChanged

        ValueChanging
    end

    properties(NonCopyable, Transient, SetAccess = protected, GetAccess = { ...
            ?matlab.ui.internal.componentframework.services.optional.ControllerInterface})

        % Stored index to scroll.  This value is used to store scroll target
        % if user calls scroll method before view is ready.
       TargetToScroll = [];
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = TextArea(varargin)
            %

            % Do not remove above white space
            % Defaults
            defaultSize = [150, 60];
            obj.PrivateInnerPosition(3:4) = defaultSize;
            obj.PrivateOuterPosition(3:4) = defaultSize;
            obj.Type = 'uitextarea';

            obj.doSetPrivateWordWrap('on');

            parsePVPairs(obj,  varargin{:});

            % Wire callbacks
            obj.attachCallbackToEvent('ValueChanged', 'PrivateValueChangedFcn');
            obj.attachCallbackToEvent('ValueChanging', 'PrivateValueChangingFcn');
        end

        % ----------------------------------------------------------------------

        function set.Value(obj, newValue)
            % Error Checking for data type
            try
                newValue = matlab.ui.control.internal.model.PropertyHandling.validateMultilineText(newValue);
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidMultilineTextValue', ...
                    'Value');

                % MnemonicField is last section of error id
                mnemonicField = 'invalidMultilineTextValue';

                % Use string from object
                messageText = getString(messageObj);

                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);

            end

            % Property Setting PrivateValue setter does conversions
            obj.PrivateValue = newValue;

            % Update View
            markPropertiesDirty(obj, {'Value'});
        end

        function value = get.Value(obj)
            value = obj.PrivateValue;
        end

        function set.PrivateValue(obj, newValue)
            % Property Setting
            obj.PrivateValue = obj.convertTextToStorableCellArray(newValue);
        end
        % -----------------------------------------------------------------

        function set.ValueChangedFcn(obj, newValue)
            % Property Setting
            obj.PrivateValueChangedFcn = newValue;

            obj.markPropertiesDirty({'ValueChangedFcn'});
        end

        function value = get.ValueChangedFcn(obj)
            value = obj.PrivateValueChangedFcn;
        end

        % -----------------------------------------------------------------
        function scroll(obj, scrollTarget)
            % SCROLL - Scroll to location within textarea
            %
            %   SCROLL(component,location) scrolls list box to the specified
            %   location within a text area. The location can be 'top', or
            %   'bottom'
            %
            %   See also UITEXTAREA


            narginchk(2, 2);
            scrollTarget = convertStringsToChars(scrollTarget);

            validTargets = {'top', 'bottom'};

            try
                scrollTarget = matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString(...
                    obj, ...
                    scrollTarget, ...
                    validTargets);
            catch me
                % Do error checking and throw error if necessary
                messageObj =  message('MATLAB:ui:components:invalidTextAreaScrollTarget', 'top', 'bottom');

                % Use string from object
                messageText = getString(messageObj);

                error('MATLAB:ui:TextArea:invalidScrollTarget', messageText);
            end

            % If the view has not been created, store the targetIndex
            % for use when the view is created.
            obj.TargetToScroll = struct('Target', scrollTarget, 'Identifier', matlab.lang.internal.uuid());

            % Dirty
            obj.markPropertiesDirty({'TargetToScroll'});
        end
        % ----------------------------------------------------------------------

        function set.ValueChangingFcn(obj, newValue)
            % Property Setting
            obj.PrivateValueChangingFcn = newValue;

            % Dirty
            obj.markPropertiesDirty({'ValueChangingFcn'});
        end

        function value = get.ValueChangingFcn(obj)
            value = obj.PrivateValueChangingFcn;
        end
    end


    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)

        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implenenting this
            % class.

            names = {'Value',...
                ...Callbacks
                'ValueChangedFcn', ...
                'ValueChangingFcn'};

        end

        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = obj.Value;

        end
    end

    methods(Access = {?matlab.ui.control.internal.controller.TextAreaController})
        function cellArray = convertTextToStorableCellArray(obj, text)
            % Treat single chars as a cell
            if(~iscell(text))
                text = {text};
            end
            if isempty(text)
                text = {''};
            end
            % convert all formatted \n's to new elements in the cell array
            % (Note: this will also turn all 1xN cell arrays into Nx1's)

            % if text has been set to '' i.e. text will be a cell with one empty char
            % {''}  which is what we want
            cellArray = text;
            % Do the conversion only if otherwise. else it results in a 0x1
            % cell array
            if(~isempty(text{1}))
                cellArray = obj.convertFormattedStrToCell(text);
            end

            % at this point, it is a valid cell array
            % transpose to Nx1
            cellArray = cellArray(:);
        end
    end

    %Helper method to convert a formatted string to a cell array
    methods(Access = 'private')
        function cellToStore = convertFormattedStrToCell(varargin)

            %the 2nd param is the one we are interested in, the 1st one is obj
            newValue = varargin{2};

            cellToStore = {};
            asciiNewLine = char(10);
            for idx = 1:length(newValue)

                thisElement = newValue{idx};

                if(~isempty(thisElement))
                    % For a formatted string like 'a\nb\nc', this will return:
                    % {'a' ; 'b'; 'c'}
                    tempCell = textscan(thisElement, '%s', ...
                        'delimiter', asciiNewLine, ...
                        'whitespace','' ...  % preserve the white spaces
                        );
                    brokenUpString = tempCell{1};

                else
                    % If the text is '', don't do the conversion, otherwise
                    % it results in a 0x1 cell array and the '' is lost.
                    % We need to wrap the empty string in a cell otherwise it
                    % gets lost in the concatenation that follows
                    brokenUpString = {thisElement};
                end

                % add to the bottom of the incremental cell we are building
                % up
                cellToStore = [cellToStore; brokenUpString];
            end
        end

    end

    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 

           % sObj is the serialization content for obj 
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj, obj);
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableComponent(sObj);
        end 
    end
end
