classdef (Hidden) StyleableComponent < appdesservices.internal.interfaces.model.AbstractModelMixin

    properties(Dependent, SetAccess = protected)
        StyleConfigurations
    end

    properties (Transient, Abstract, Access = {?appdesservices.internal.interfaces.model.AbstractModelMixin})
        TargetEnums
        TargetDefault
    end

    methods (Abstract, Access = protected)
        % Component specific validation
        index = validateStyleIndex(obj, target, index);

    end

    properties(Access = ...
            {?matlab.ui.internal.componentframework.services.optional.ControllerInterface,...
             ?matlab.ui.style.internal.StylesMetaData})
        StyleConfigurationStorage;
    end

    methods

        % ----------------------------------------------------------------------
        function value = get.StyleConfigurations(obj)
            value = obj.StyleConfigurationStorage.createStyleConfigurations(obj, obj.TargetEnums);
        end
        % ----------------------------------------------------------------------
        function set.StyleConfigurationStorage(obj, newValue)
            % Property Setting
            obj.StyleConfigurationStorage = newValue;

            obj.markPropertiesDirty({'StyleConfigurationStorage'});
        end

        function value = get.StyleConfigurationStorage(obj)
            if isempty(obj.StyleConfigurationStorage)
                value = matlab.ui.style.internal.StylesMetaData.initialStyleConfigurationStorage();
            else
                value = obj.StyleConfigurationStorage;
            end
        end

        function addStyle(obj, styleObject, varargin)
            %ADDSTYLE Add style to tree UI component
            %
            %   ADDSTYLE(tr,s) adds a style created with the uistyle function to
            %   the specified tree UI component. The style is applied to the whole
            %   tree. The uitree must be parented to a figure created with the
            %   uifigure function, or to one of its child containers.
            %
            %   ADDSTYLE(tr,s,target,targetIndex) adds the style to
            %   a specific node or tree level. For example,
            %   addStyle(uit,s,'level',1) adds the style to the first level of the
            %   specified tree UI component.
            %
            %   Example: Add Multiple Styles to Tree
            %      % Create a tree in a figure.
            %
            %      fig = uifigure('Position',[100 500 730 267]);
            %      tr = uitree(fig);
            %      node1 = uitreenode(tr, "Text", "Node 1");
            %      node2 = uitreenode(tr, "Text", "Node 2");
            %      node11 = uitreenode(node1, "Text", "Node 1.1");
            %      node12 = uitreenode(node1, "Text", "Node 1.2");
            %
            %      tr.Position = [20 10 650 246];
            %
            %      % Create a style that sets background color to red and add it to the entire tree
            %      s1 = uistyle;
            %      s1.BackgroundColor = 'red';
            %
            %      addStyle(tr,s1)
            %
            %      % Then, create additional styles and add them to the tree.
            %      s2 = uistyle;
            %      s2.BackgroundColor = 'green';
            %
            %      s3 = uistyle;
            %      s3.FontWeight = 'bold';
            %      s3.FontAngle = 'italic';
            %      s3.FontColor = 'blue';
            %
            %      addStyle(tr,s2,'level',1)
            %      addStyle(tr,s3,'node',[node2; node12])
            %
            %   See also UISTYLE, UITREE
            %

            %   Copyright 2021 The MathWorks, Inc.

            narginchk(2, 4);

            % Validate Style
            styleClass = 'matlab.ui.style.internal.ComponentStyle';
            if ~isa(styleObject, styleClass) || ~isscalar(styleObject)
                messageObject = message('MATLAB:ui:style:invalidStyleObject', ...
                    'Style');

                % MnemonicField is last section of error id
                mnemonicField = 'invalidStyleObject';

                % Use string from object
                messageText = getString(messageObject);

                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
            end

            switch nargin
                case 2
                    % Default target is entire component. Each component
                    % will specify a keyword in 'TargetDefault'
                    newTarget = obj.TargetDefault;
                    newIndex = {''};

                case 3
                    % Incorrect number of input arguments
                    messageObject = message('MATLAB:ui:style:invalidNumberOfInputs');

                    % MnemonicField is last section of error id
                    mnemonicField = 'invalidNumberOfInputs';

                    % Use string from object
                    messageText = getString(messageObject);

                    % Create and throw exception
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                    throw(exceptionObject);

                case 4
                    shouldThrowGenericError = false;
                    [inputTarget, inputIndex] = varargin{:};

                    % Convert strings and string arrays to chars and cellstrs
                    if iscell(inputIndex)
                        inputIndex = cellfun(@convertStringsToChars, inputIndex, ...
                            'UniformOutput', false);
                    else
                        inputIndex = convertStringsToChars(inputIndex);
                    end

                    if ~(ischar(inputTarget) || iscellstr(inputTarget)  || isstring(inputTarget) || iscategorical(inputTarget))
                        % The inputTarget is expected to be a string, char
                        % or categorical
                        % Handle this basic check so component speci
                        shouldThrowGenericError = true;
                    end

                    % Validate Target and TargetIndex combinations
                    % 'Target' can be a char or categorical
                    if ~shouldThrowGenericError
                        if strcmpi(inputTarget, obj.TargetDefault) || ...
                                (iscategorical(inputTarget) && inputTarget == obj.TargetDefault)
                            inputTarget = obj.TargetDefault;

                            if ~isValidDefaultIndex(obj, inputIndex)
                                messageObject = message('MATLAB:ui:style:invalidTargetIndex', ...
                                    inputTarget);
                                % MnemonicField is last section of error id
                                mnemonicField = 'invalidTargetIndex';

                                % Use string from object
                                messageText = getString(messageObject);

                                % Create and throw exception
                                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                                throw(exceptionObject);
                            else
                                % Ensure index is an empty char
                                inputIndex = '';
                            end

                        else
                            inputIndex = validateStyleIndex(obj, inputTarget, inputIndex);

                        end
                    end
                    if shouldThrowGenericError || ~any(strcmpi(string(inputTarget), obj.TargetEnums))
                        % g2790115
                        assert(numel(obj.TargetEnums) == 4 || numel(obj.TargetEnums) == 2 , "Number of enums for this error message is expected to be 2 (listbox) or 4 (tree).")
                        
                        switch numel(obj.TargetEnums)
                            case 4
                            messageObject = message('MATLAB:ui:style:invalidStyleTargetFourOptions', ...
                            obj.TargetEnums(1), obj.TargetEnums(2), obj.TargetEnums(3), obj.TargetEnums(4));

                            case 2
                            messageObject = message('MATLAB:ui:style:invalidStyleTargetTwoOptions', ...
                            obj.TargetEnums(1), obj.TargetEnums(2));
                        end                        

                        % MnemonicField is last section of error id
                        mnemonicField = 'invalidStyleTarget';

                        % Use string from object
                        messageText = getString(messageObject);

                        % Create and throw exception
                        exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                        throw(exceptionObject);
                    end

                    newTarget = string(lower(inputTarget));
                    newIndex = {inputIndex};
            end

            % update style configuration
            updateStyleConfigurationStorage(obj, newTarget, newIndex, styleObject);
        end

        function removeStyle(obj, varargin)
            %REMOVESTYLE Remove style from a tree, listbox, or dropdown UI component
            %
            %   REMOVESTYLE(comp) removes all styles created with the uistyle function
            %   from the specified tree UI component. To determine which styles are on
            %   uit and available to remove, query the value of uit.StyleConfigurations.
            %
            %   REMOVESTYLE(comp,ordernum) specifies which style to remove.
            %   The property uit.StyleConfigurations lists styles in the
            %   order that they were added.
            %
            %   Example: Remove Style from tree
            %      % Remove a single style from a tree.
            %      % First, create a tree and add styles to it.
            %      s1 = uistyle('BackgroundColor','red');
            %      s2 = uistyle('BackgroundColor','yellow');
            %
            %      fig = uifigure;
            %      fig.Position = [100 100 520 220];
            %      tr = uitree(fig);
            %      node1 = uitreenode(tr, "Text", "Node 1");
            %      tr.Position = [20 30 480 135];
            %
            %      addStyle(tr,s1,'level',1)
            %      addStyle(tr,s2,'node',node1)
            %
            %      % Now, remove the first style added to the tree by specifying order
            %      % number 1.
            %      removeStyle(tr,1)
            %
            %   See also UISTYLE, UITREE
            %

            %   Copyright 2021 The MathWorks, Inc.

            narginchk(1, 2);

            switch nargin
                case 1
                    % Remove all styles
                    removeFromStyleTable(obj, 'all', '');
                case 2
                    removedStyle = varargin{1};

                    if (isValidOrder(obj, removedStyle))
                        % If scalar numeric or numeric array
                        % Remove the style at that order number
                        removeFromStyleTable(obj, 'numeric', removedStyle);
                    else
                        messageObject = message('MATLAB:ui:style:invalidRemovalIndex');

                        % MnemonicField is last section of error id
                        mnemonicField = 'invalidRemovalIndex';

                        % Use string from object
                        messageText = getString(messageObject);

                        % Create and throw exception
                        exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                        throw(exceptionObject);
                    end
            end
        end

    end
    methods(Access = private)

        function isValid = isValidDefaultIndex(~, idx)
            % Default index is valid if it is empty
            isValid = isempty(idx);
        end

        function updateStyleConfigurationStorage(model, newTarget, newIndex, newStyle)
            matlab.ui.style.internal.StylesMetaData.addStyle(model, newTarget, newIndex, newStyle);

        end
        function removeFromStyleTable(obj, indexType, removedStyle)
            matlab.ui.style.internal.StylesMetaData.removeStyle(obj, indexType, removedStyle);
        end

        function validOrder = isValidOrder(~, ord)
            % An order is valid if it is a scalar or array of positive integers
            try
                validateattributes(ord,{'numeric'},{'positive','integer','real','finite','vector','nonempty'});
                validOrder = true;
            catch
                validOrder = false;
            end
        end
    end
end