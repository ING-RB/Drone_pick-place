classdef ComponentCodeGenerator
    %COMPONENTCODEGENERATOR - This class has all knowledge to use the
    %adapters to assemble code for a component.
    
    % Copyright 2017-2022 The MathWorks, Inc.
    
    properties (Access = 'private', Transient)
        
        % Map of component specific data.  The key is the component type
        % and the value is a struct with three fields
        %   ComponentDefaults - a struct containing default values for each
        %   field of the component
        %   PropertyList - a 1xn cell array of property names for the
        %   component in the order they should appear in the generated code
        ComponentData = containers.Map();
    end
    
    properties (Constant)
        AppObjectName = 'app'
        CustomUIComponentObjectName = 'comp'
    end
    
    methods
        function obj = ComponentCodeGenerator()
        end
        
        function generatedCode = getComponentGenerationCode(obj, model, adapter, appType, theme)
            arguments
                obj
                model
                adapter
                appType
                theme = 'unthemed'
            end
            % GETCOMPONENTCODE - This class uses the current state of the
            % model and the adapter to generate a cell array of strings
            % representing the code to generate that component.
            % Example generated code
            %      {'ad_OBJECTNAME_ad.ad_CODENAME_ad = uilabel(ad_OBJECTNAME_ad.ad_PARENTCODENAME);'}
            %      {'ad_OBJECTNAME_ad.ad_CODENAME_ad.Location = [100 20]'}

            % Get Code replacement map.
            if isempty(theme)
                theme = 'unthemed';
            end
            replaceMap = appdesigner.internal.codegeneration.ComponentCodeGenerator.getCodeReplaceMap();
            componentType = adapter.ComponentType;
            if obj.ComponentData.isKey(componentType)
                % Get per component data from the map
                componentData = obj.ComponentData(componentType);

                % Theme might be changed since the Component Defaults were
                % cached. Hence, check if the map contains defaults
                % for the argued theme.
                if isfield(componentData.ComponentDefaults, theme)
                    componentDefaults = componentData.ComponentDefaults.(theme);
                else
                    componentDefaults = adapter.getComponentRunTimeDefaults(theme);
                    componentData.ComponentDefaults.(theme) = componentDefaults;
                    obj.ComponentData(componentType) = componentData;
                end

                propertyList = componentData.PropertyList;
            else
                % Calculate the per component data once, then store it in
                % the ComponentData map
                componentDefaults = adapter.getComponentRunTimeDefaults(theme);
                
                % Property List in the order it should appear in the code
                propertyList = adapter.getCodeGenPropertyNames(model);

                % Store component specific information in a
                % struct, then add entry to ComponentData map.
                componentData = struct();
                componentData.ComponentDefaults = struct();
                componentData.ComponentDefaults.(theme) = componentDefaults;
               
                componentData.PropertyList = propertyList;

                if (adapter.shouldCacheCodegenProperties)
                    obj.ComponentData(componentType) = componentData;
                end
            end

            % Remove Component Position Property if component is in GridLayout g2574660
            if (isa(model.Parent, 'matlab.ui.container.GridLayout'))
                index = find(strcmp(propertyList,'Position' ));
                if ~isempty(index) 
                    propertyList(index) = [];
                end
            end 

            % Generate component code using the adapter methods as helpers.
            % componentStr will be something like:
            %    'ad_OBJECTNAME_ad.ad_CODENAME_ad = uilabel(app.ad_PARENTCODENAME);'
            componentStr = obj.generateComponentConstructor(...
                model,...
                adapter,...
                replaceMap('CodeName'),...
                replaceMap('ParentCodeName'),...
                replaceMap('ObjectName'));

            % Generate component code to set the properties on the model
            % propertiesStr will be a cell array, one string per property
            % set, for example:
            %       {'ad_OBJECTNAME_ad.ad_CODENAME_ad.Location = [200 200]'}
            %       {'ad_OBJECTNAME_ad.ad_CODENAME_ad.Size = [100 20]'}
            propertiesStr = obj.generateComponentProperties(...
                model, ...
                adapter,...
                replaceMap('ObjectName'), ...
                replaceMap('CodeName'), ...
                replaceMap('ParentCodeName'), ...
                propertyList, ...
                componentDefaults);

            generatedCode = obj.removeObjectNameToken([{componentStr}; propertiesStr], replaceMap('ObjectName'), appType);
        end
    end
    
    methods (Static)
        
        function replaceMap = getCodeReplaceMap()
            % Here is a class that stores the replacement strings code
            % generation will use when components generate code.  The
            % strings will be replaced in a code model object on the client
            % and the code item will update the view if one of these
            % properites changes.
            
            keyValuePairs = {'CodeName', 'ad_CODENAME_ad';...
                'ParentCodeName', 'ad_PARENTCODENAME_ad';...
                'ObjectName', 'ad_OBJECTNAME_ad'};
            
            % Create Map for the replacements.  All entries
            % should be string, so set uniformValues to true
            replaceMap = containers.Map(keyValuePairs(:, 1), keyValuePairs(:, 2), ...
                'uniformValues', true);
            
        end
    end
    
    % The following block contains functions specific to generating code
    %  using the MATLAB component adapters
    methods(Access = private)
        function generatedCode = removeObjectNameToken(obj, code, token, appType)
            objectName = obj.AppObjectName;
            
            if (strcmp(appType, appdesigner.internal.serialization.app.AppTypes.UserComponentApp))
                objectName = obj.CustomUIComponentObjectName;
            end
            
            generatedCode = strrep(code, token, objectName);
        end

        function entireLine = generateComponentConstructor(obj,...
                model, adapter, codeName, parentCodeName, objectName)
            % Generates a single line to create the component
            %
            % Ex: app.CircularGauge = uigauge(app.UIFigure, 'circular');
            
            % Ex: app.UIFigure
            parentVariableName = sprintf('%s.%s', objectName, parentCodeName);
            
            % The right hand side for the component creation
            %
            % Ex: uigauge(UIFigure, 'circular')
            componentCreationSnippet = adapter.getCodeGenCreation( ...
                model, codeName, parentVariableName);
            
            % Create the entire line
            %
            % (indent) app.CircularGauge = (component creation snippet)
            entireLine = sprintf('%s.%s = %s;', ...
                objectName, ...
                codeName, ...
                componentCreationSnippet);
        end
        
        function propertyStr = generateComponentProperties(obj, model, adapter,...
                objectName, codeName, parentCodeName, propertyList, defaultComponent)
            
            % The propertyList order should be honored and assumed to be
            % correct.
            %
            % In general we will not generate code if the property value is
            % the same as the default.
            % If the propertyName has a 'Mode' sibling, and the 'Mode'
            % sibling is manual, we should always generate the code for
            % that propertyName.
            
            
            propertyStr = [];
            for index = 1:numel(propertyList)
                propertyName = propertyList{index};
                
                showPropertyCode = adapter.shouldShowPropertySetCode(...
                    model,...
                    propertyName, ...
                    defaultComponent);
                
                if showPropertyCode
                    % Ask adapter how to generate the line of code that
                    % sets this specific value
                    try
                        propertySegment = adapter.getCodeGenPropertySet(model, objectName, propertyName, codeName, parentCodeName);
                        if ~iscell(propertySegment)
                            % convert the code string to a cell array if
                            % it's just a character vector
                            propertySegment = {propertySegment};
                        end
                        % Format the propertySegment to include leading white
                        % space the equivalent of three tabs, add a newline to
                        % the end of the property segment
                        propertyStr = [propertyStr; propertySegment];
                    catch e
                    end
                end
            end
            
        end
    end
    
    methods ( Static, Access = {?appdesigner.internal.componentadapterapi.VisualComponentAdapter,...
            ?appdesigner.internal.usercomponent.UserComponentPropertyUtils,...
            ?tComponentCodeGenerator} )
        
        function valueStr = propertyValueToString(className, value)
            % This function returns a string representing the values to be
            % modified for the component.  The string returned would be:
            % '[105 399]'
            % in order to modify the Location property of app.Pushbutton1:
            % app.PushButton1.Location = [105 399];
            
            import appdesigner.internal.codegeneration.ComponentCodeGenerator
            
            valueStr = '';
            switch(class(value))
                case { 'matlab.lang.OnOffSwitchState'}
                    if (value == matlab.lang.OnOffSwitchState.off)
                        valueStr = sprintf("'%s'", 'off');
                    else
                        valueStr = sprintf("'%s'", 'on');
                    end
                    
                case {'logical', 'double'}
                    valueStr = mat2str(value);
                    
                case {'datetime'}
                    valueStr = ComponentCodeGenerator.generateDateTime(value);
                    
                case {'string'}
                    valueStr = ComponentCodeGenerator.escapeNewline(value);
                    
                case {'char'}
                    value = ComponentCodeGenerator.escapeQuote(value);
                    valueStr = ComponentCodeGenerator.escapeNewline(value);

                case {'cell'}
                    % case of empty cell
                    if numel(value) == 0
                        valueStr = '{}';
                        % case of 1x1 cell
                    elseif numel(value) == 1
                        % Values in cell can be string or double
                        % 'States' property can be a double
                        
                        if ischar(value{1})
                            % 1x1 cells containing characters
                            splitValue = ComponentCodeGenerator.escapeQuote(value{1});
                            splitValue = ComponentCodeGenerator.escapeNewline(splitValue);
                            valueStr = sprintf('{%s}', splitValue);
                        elseif (isnumeric(value{1})...
                                || islogical(value{1}))...
                                && numel(value{1}) == 1
                            % cell array of 1
                            valueStr = sprintf('{%g}', value{1});
                        end
                        % case of nx1 or 1xn cell array
                    elseif numel(value) == length(value)
                        % case of nx1 cell array
                        
                        if ischar(value{1})
                            splitValue = ComponentCodeGenerator.escapeQuote(value{1});
                            splitValue = ComponentCodeGenerator.escapeNewline(splitValue);
                            valueStr = sprintf('{%s', splitValue);
                        elseif (isnumeric(value{1})...
                                && numel(value{1}) == 1)
                            valueStr = sprintf('{%g', value{1});
                            
                        elseif (islogical(value{1}) && numel(value{1}) == 1)
                            if value{1}
                                valueStr = '{true';
                            else
                                valueStr = '{false';
                            end
                        else
                            assert(false, ...
                                sprintf(...
                                'Unexpected data type found for %s',...
                                className))
                        end
                        
                        % case of 1xn cell array
                        if size(value, 2) == length(value)
                            separator = ',';
                        else
                            separator = ';';
                        end
                        % On a rare occasion, a 1xn cell array may be of
                        % mixed type which is why each value should be
                        % handled separately.
                        for entry = ...
                                reshape(value(2:end), ...
                                1, numel(value(2:end)))
                            if ischar(entry{1})
                                entryStr = ComponentCodeGenerator.escapeQuote(entry{1});
                                entryStr = ComponentCodeGenerator.escapeNewline(entryStr);
                                valueStr = ...
                                    sprintf('%s%s %s', ...
                                    valueStr, separator,...
                                    entryStr);
                            elseif (isnumeric(entry{1})...
                                    && numel(entry{1}) == 1)
                                valueStr = ...
                                    [valueStr, sprintf('%s %g', ...
                                    separator, entry{1})]; %#ok<AGROW>
                            elseif (islogical(entry{1}) && numel(entry{1}) == 1)
                                if entry{1}
                                    valueStr = ...
                                        [valueStr, sprintf('%s %s', ...
                                        separator, 'true')]; %#ok<AGROW>
                                else
                                    valueStr = ...
                                        [valueStr, sprintf('%s %s', ...
                                        separator, 'false')]; %#ok<AGROW>
                                end
                            else
                                assert(false, ...
                                    sprintf(...
                                    'Unexpected data type found for %s',...
                                    className))
                            end
                        end
                        valueStr = [valueStr, '}'];
                    end

                case {'matlab.ui.container.TreeNode'}
                    valueStr = '';
                    comma = '';
                    space = "";
                    for i = 1:numel(value)
                        if i ~= 1
                            comma = ',';
                            space = " ";
                        end
                        valueStr = strcat(valueStr, comma, space, 'ad_OBJECTNAME_ad.', value(i).DesignTimeProperties.CodeName);
                    end
                    valueStr = strcat('[', valueStr, ']');

                case 'matlab.graphics.theme.GraphicsTheme'
                    valueStr =  sprintf("'%s'", value.BaseColorStyle);

                otherwise
                    % This will catch future component properties that are
                    % not currently implemented by may be in the future
                    % TODO, deal with LABELS
                    
                    % Fall through for User Component Enum properties.
                    % User component Enum properties can be of any class.
                    % So it cannot fit into the above switch case.
                    if isenum(value)
                        value = char(value);
                        valueStr = sprintf('''%s''', ComponentCodeGenerator.escapeQuote(value));
                    else
                        assert(false, ...
                            ['This compare class has '...
                            'not been implemented: %s'],...
                            class(value));
                    end
                    
            end
            
            
        end
        
        function str = escapeQuote(str)
            % sprintf will format '' to be ', so this doubles the
            % single quotes so they are preserved through sprintf
            str = regexprep(str, '''', '''''');
        end

        function str = escapeNewline(str)
            % ESCAPENEWLINE - replaces newline characters
            %   "hello\nworld" -> '"hello" + newline + "world"'
            %   'hello\nworld' -> '['hello' newline 'world']'
            
            str = strsplit(str, newline);
            if isstring(str)
                str = sprintf('"%s"', strjoin(str, '" + "'));
            else
                % cell of char vectors
                if length(str) > 1
                    str = sprintf('[''%s'']', strjoin(str, ''' newline '''));
                else
                    str = sprintf('''%s''', strjoin(str));
                end
            end
        end
        
        function cellStr = generateStringForPropertySegment(objectName, codeName, ...
                thisProperty, value)
            % Example text to add the Location property to HmiFigure1:
            % app.HmiFigure1.Location = [50 50];
            
            % This is the value in the form of a char where feval(valueStr)
            % would help produce a value that is equivalent to the original
            cellStr = {};
            
            if strcmp(thisProperty, 'Layout')
                % Code generation for Layout property of the component when
                % it's parented to GridLayout
                constraintsStruct = matlab.ui.control.internal.controller.mixin.LayoutableController.convertContraintsToStruct(value);
                
                if strcmp(constraintsStruct.Type, 'Grid')
                    % Only generate code for Layout if the Type is Grid,
                    % and do not generate code for pixel-based, e.g. Absolute
                    rowValueStr = appdesigner.internal.codegeneration.ComponentCodeGenerator.propertyValueToString(codeName, constraintsStruct.Row);
                    columnValueStr = appdesigner.internal.codegeneration.ComponentCodeGenerator.propertyValueToString(codeName, constraintsStruct.Column);
                    cellStr = {...
                        sprintf('%s.%s.%s.Row = %s;', ...
                        objectName, codeName, thisProperty, rowValueStr);...
                        sprintf('%s.%s.%s.Column = %s;', ...
                        objectName, codeName, thisProperty, columnValueStr)...
                        };
                end
            else
                valueStr = appdesigner.internal.codegeneration.ComponentCodeGenerator.propertyValueToString(codeName, value);
                cellStr = {sprintf('%s.%s.%s = %s;', ...
                    objectName, codeName, thisProperty, valueStr)};
            end
        end
        
        function dateTimeChar = makeDateTimeRHS(value)
            if isnat(value)
                dateTimeChar = 'NaT';
            else
                numericVal = [value.Year, value.Month, value.Day];
                dateTimeChar = sprintf('datetime(%s)', mat2str(numericVal));
            end
        end
        
        function dateTimeRHS = generateDateTime(value)
            import appdesigner.internal.codegeneration.ComponentCodeGenerator
            
            dateTimeSize = size(value);
            if max(dateTimeSize) == 1
                dateTimeRHS = ComponentCodeGenerator.makeDateTimeRHS(value);
            else
                dateTimes = arrayfun(@(x)ComponentCodeGenerator.makeDateTimeRHS(x), value, 'UniformOutput', false);
                spacer = ' ';
                if dateTimeSize(1) > dateTimeSize(2)
                    spacer =  '; ';
                end
                dateTimeRHS = ['[' strjoin(dateTimes, spacer) ']'];
            end
            
        end
        
    end
end
