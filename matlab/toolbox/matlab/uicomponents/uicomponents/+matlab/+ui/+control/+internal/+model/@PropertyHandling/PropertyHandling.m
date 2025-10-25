classdef (Hidden) PropertyHandling
    % This undocumented class may be removed in a future release.
    
    % PropertyHandling contains static methods for processing and
    % validating property values common to different visual components.
    % 
    % In order to reduce the overhead associated to parsing this class,
    % some of its methods have been defined in separate files. The criteria
    % that was used in order to determine if a method of this class goes
    % into a separate file was the following:
    %     1) Methods with ~10 or more lines of code were moved into
    %     separate files
    %     2) Methods referencing other classes, functions or static methods
    %     of the class that are defined in MATLAB and trigger additional parsing, 
    %     were also moved into separate files irrespective of how many lines 
    %     of code they had
    
    % Copyright 2011-2022 The MathWorks, Inc.
    
    % ---------------------------------------------------------------------
    % Functions for use by Visual Components
    % ---------------------------------------------------------------------
    methods(Static)
        exceptionObject = createException(component, mnemonicField, messageText, varargin);
        
        displayWarning(component, mnemonicField, messageText, varargin);
        
        messageWithDocLink = createMessageWithDocLink(errorText, linkId, docFunction);
        
        function className = getComponentClassName(component)
            % Returns the class name of a component.
            % The class name is stripped from the package name.
            % E.g.
            % The returned class name for an instance of the class
            % matlab.ui.control.Button is 'Button'
            
            if ischar(component)
                % The class name was given, not the instance. Return as is.
                className = component;
            else
                % Input was an instance
                
                % Full class name of component including package
                % information
                className = class(component);
                
                % Separate class name into separate strings that represent
                % the packages and class name
                packageStrings = regexp(className, '\.', 'split');
                
                % The Component Name is the
                className = packageStrings{end};
            end
        end
        
        function result = isPositiveNumber(value)
            % Returns whether value is a positive number 
            % Value must be real, finite, not NaN
            % e.g. 10
            
            result = isscalar(value) && isnumeric(value) && isreal(value) && isfinite(value) && ~isnan(value) && value >= 0;
        end
        
        function result = isRowOf4PositiveNumbers(value)
            % Returns whether value is a row vector of 4 elements where
            % each element is a positive number.
            % Each element must be real, finite, not NaN
            % e.g. [10, 20, 10, 20];
            
            try
                validateattributes(value, ...
                    {'numeric'}, ...
                    {'row', 'numel', 4, 'real', 'finite', 'nonnan', '>=', 0}); 
                result = true;
            catch ME %#ok<NASGU>
                result = false;
            end            
        end
        
        function result = isString(value)
            % Returns whether value is a string.
            
            % Note: check for empty string separately because isrow
            % of empty string returns false
            result = ischar(value) && (isrow(value)||strcmp(value,''));
        end
        
        function isElementPresent = isElementPresent(element, array)
            % Checks if ELEMENT is in ARRAY, according to isequal(), and
            % returns true or false.
            %
            % Inputs:
            %
            %  ARRAY -  a 1xN array or cell array
            %
            %           All elements in the array must support isequal().
            %
            % Ouputs:
            %
            %  ISELEMENTPRESENT - true if ELEMENT was found in ARRAY,
            %                     according to isequal()
            narginchk(2, 2)
            
            if(isempty(array))
                isElementPresent = false;
                return;
            end
            
            if(iscell(array))
                if(isempty(element) && isa(element, 'double'))
                    isElementPresent = false;
                else
                    % Ex: array = {'a', 'b', 'c'}
                    isElementPresent = any(cellfun(@(x) isequal(x, element), array));
                end
            else
                % numeric array
                % Ex: array = [1 2 3]
                isElementPresent = any(arrayfun(@(x) isequal(x, element), array));
            end
        end
        
        areElementsPresent = areElementsPresent(elements, array);
        
        areElementsPresent = areElementsPresentUsingIsEqual(elements, array);
        
        isElementPresent = isTextElementPresent(element, array);
        
        index = findElementInVector(element, array);
        
        function index = findElementInVectorUsingIsequal(element, array)
            % FINDINDEXOFELEMENTINVECTOR - This function mimics find and
            % returns the indicies of the array that match the element
            %
            % Functionality mirrors findElementInVector
            % Functionality is robust across all datatypes, but may be a
            % slower choice than ismember and other types of
            % comparisons that work better for specific datatypes

                % Find the index of valueData in ItemsData
                % If there are duplicates, pick the first one
                if(iscell(array))
                    index = find(cellfun(@(x) isequal(x, element), array), 1);
                else
                    index = find(arrayfun(@(x) isequal(x, element), array), 1);
                end

        end
        
        function index = findTextElementInVector(element, array)
            % FINDINDEXOFELEMENTINVECTOR - This function mimics find and
            % returns the indicies of the array that match the element
            % element = scalar string or vector char array
            % array - vector cellstr or vector string array
            
            % Get boolean report of whether elements are present
            isElementPresent = strcmp(element, array);
            
            % Get Index matches
            index = find(isElementPresent);
            if numel(index) > 1
                index = index(1);
            end
        end

        output = processCellArrayOfStrings(component, propertyName, input, sizeConstraints);
        
        output = processEnumeratedString(component, input, availableStrings);
        
        output = processMode(component, input);
        
        output = processItemsDataInput(component, propertyName, input, sizeConstraints);
        
        [isValid, extraElement] = validateSubset(subset, fullset);
        
        isElementAcceptable = validateStatesElement(element);
        
        function newValue = validateLogicalScalar(value)
            % Validates that VALUE is a logical scalar.
            % As per PRISM standards, also accept 0/1 and convert to logical scalar
            
            try
                % check for 0/1
                validateattributes(value,...
                    {'numeric'},...
                    {'scalar','integer','<=',1,'>=',0});
                
                % convert to the corresponding logical
                newValue = value == 1;
            catch ME %#ok<NASGU>
                % check for logical scalar
                validateattributes(value, ...
                    {'logical'}, ...
                    {'scalar'});
                
                % convert to logical explicitly in case value is in an enum
                % class that is derived from the logical class
                newValue = logical(value);
            end
        end
        
        function newValue = convertOnOffToTrueFalse(value)
            % Converts on/off to true/false
            %
            % This assumes that validation on value has already been done
            % so that value is either 'on' or 'off'
            
            newValue = strcmp(value, 'on');
            
        end
        
        function newValue = convertTrueFalseToOnOff(value)
            % Converts true/false to on/off
            
            if(value)
                newValue = 'on';
            else
                newValue = 'off';
            end
        end
        
        function labels = convertArrayToLabels(array)
            % Converts the given array to labels.
            %
            % Inputs:
            %
            %  ARRAY   - The array to convert to labels
            %
            % Outputs:
            %
            %  LABELS - a cell array of strings, the same size of array
            %
            % The following rules are used when converting ARRAY to
            % strings:
            %
            %   - numeric scalar   -> num2str()
            %
            %   - logical scalar   -> true becomes 'On'
            %                         false becomes 'Off'
            %
            %   - string           -> as is
            %
            % All other data types are not supported.
            %
            if(iscell(array))
                labels = cellfun(@convertElementToLabel, ...
                    array, 'UniformOutput', false);
            else
                labels = arrayfun(@convertElementToLabel, ...
                    array, 'UniformOutput', false);
            end
        end
        
        function newText = validateText(text)
            % Validates that TEXT is a valid string
            %
            % '' or a string like 'abc', "abc"
            %
            % Input:
            %
            % text - The user enetered value
            %
            % Output:
            %
            % newText - User entered value validated and converted to char
            %
            % Column - vector strings are dissallowed
            
            % Convert string input to char
            if((isstring(text) && isempty(text)))
                % Change text to '' if string.empty
                newText = '';
                return
            else
                % Convert string to char
                newText = convertStringsToChars(text);

                if isa(newText, 'char')
                    % Check for char empty because it is not a row
                    if(isempty(newText))
                        % Assign empty char as text
                        newText = '';
                        return;
                    elseif isrow(newText)
                        % No-op: newText is a valid char row, like 'abc'
                        return;
                    end
                end
            end
            % This is always expected to fail.  Use
            % validateattributes for consistent error message
            validateattributes(text, ...
                {'char'}, ...
                {'row'});
            newText = text;
        end
        
        newText = validateAnnotationText(text);
        
        rowVectorLimits = validateFiniteLimitsInput(component, limits);
        
        rowVectorLimits = validateLimitsInput(component, limits);

        rowVectorLimits = validateNonDecreasingLimitsInput(component, limits);
        
        output = validateScalarOrIncreasingArrayOf2(input);
        
        newTicks = validateTickArray(component, ticks, propertyName);
        
        array = getSortedUniqueVectorArray(array, direction);
        
        function array = getOrientedVectorArray(array, direction)
            % GETSORTEDUNIQUEVECTORARRAY
            % This utility assumes that the input is a valid vector array.  
            % It returns the vector in a consistent direction            
            
            % Orient array
            if strcmp(direction, 'horizontal') && iscolumn(array) || ...
               strcmp(direction, 'vertical') && isrow(array)
                    array = array';
            end
                
                           
        end
        
        validateNonInfElements(component, array);

        newText = validateMultilineText(text);
        
        newColor = validateColorSpec(component, color);
        
        newColors = validateColorsArray(component, colorArray);
        
        convertedFormatString = validateDisplayFormat(component, newFormatString, propertyName, currentValue);
        
        function newValue = calibrateValue(limits, value)
            % Given the scale limits, and value, recalibrates the value to
            % ensure that it is within the limits.
            %
            % If the value is above the limits, then it will be calibrated
            % to the upper limit.
            %
            % If the value is below the limits, then it will be calibrated
            % to the lower limit.
            
            
            if(value < limits(1))
                % current value is below the new limits
                newValue = limits(1);
            elseif(value > limits(2))
                % current value is above the existing limits
                newValue = limits(2);
            else
                newValue = value;
            end
        end
        
        dataTickDelta = findDataTickDelta(lower, upper, width);
        
        [autoModeProperties, siblingAutoProperties, manualModeProperties, siblingManualProperties] = getModeProperties(propertyValuesStruct);
        
        [siblingProperties, modeProperties] = getPropertiesWithMode(objectClassName, propertyValuesStruct, includeHiddenProperty);
        
        shiftedPVPairs = shiftOrderDependentProperties(pvPairs, orderDependentProperties, component);
    end
end

% ---------------------------------------------------------------------
% Private Helper Methods for the PropertyHandling functions
% ---------------------------------------------------------------------
function label = convertElementToLabel(element)
if(isnumeric(element))
    
    label = sprintf('%1.4g', element);
    return;
elseif(ischar(element))
    % take the string as is
    label = element;
    return;
elseif(islogical(element))
    % true = 'On'
    % false = 'Off'
    if(element)
        label = getString(message('MATLAB:ui:defaults:trueStateLabel'));
    else
        label = getString(message('MATLAB:ui:defaults:falseStateLabel'));
    end
    return;
end

% Some unexpected type
assert(false, 'The given data type was not expected');
end