classdef (Hidden) ComponentCreation
    %COMPONENTCREATION Suite of functions to assist with informal object
    %creation.
    %
    % Static Methods:
    %
    %  createComponent - Creates a single component given the class name
    %                    and PV Pairs.
    %
    %  createComponentInFamily - Creates a single component that lives in a
    %                            family of components, given the class name
    %                            and the user specified style string.        
    
    methods(Static)
        function component = createComponent(creationOptions)
            % Helper used by informal functions to create a single
            % component that is not in a family.
            % 
            % This should be used by convenience functions that support the following
            % syntaxes:
            %
            %   obj = fun('PropertyName1', value1, 'PropertyName2', value2, ...)
            %
            %   obj = fun(parentHandle, ...)
            %
            % Inputs:
            %
            %   See createComponentInFamily() for the input descriptions.                        
            import matlab.ui.control.internal.model.ComponentCreation;            
            
            % Validation / parsing
            %
            % Note we do not use 'arguments' because it was not as
            % performant
            className = creationOptions.className;            
            functionName = creationOptions.functionName;            
            userInputs = creationOptions.userInputs;
            isComponentContainer = isfield(creationOptions, 'isComponentContainer') && creationOptions.isComponentContainer;
            
            [parent, args] = ComponentCreation.getOptionalParent(functionName, userInputs{:});            

            % create the component
            component = createComponentAndSetParent(className, functionName, args, parent, isComponentContainer);
            
            % If the user did not set Parent through PV Pairs, then set it
            % to a new parent
            if(strcmp(component.ParentMode,'auto'))
                parentHandle = ComponentCreation.createDefaultParent(functionName);
                component.Parent = parentHandle;
            end
        end
        
        function component = createComponentInFamily(creationOptions)
            % Helper used by informal functions to create components
            % that live in a family of components
            %
            % This should be used by convenience functions that support the following
            % syntaxes:
            %
            %   obj = fun('PropertyName1', value1, 'PropertyName2', value2, ...)
            %
            %   obj = fun(style, ...)
            %
            %   obj = fun(parentHandle, ...)
            %
            %   obj = fun(parentHandle, style, ...)
            %
            % Inputs:
            %
            %  styleNames - a cell array of strings for each available style
            %
            %           Ex: {'foo', 'bar'}
            %
            %  classNames - a cell array of strings, each of which is a fully qualified
            %               MATLAB class.  Each class path corresponds to an element in
            %               STYLES, meaning when a user specifies the iTH style, and
            %               iTH class will be created.
            %
            %               All objects are assumed to:
            %                 - have a public constructor
            %                 - takes no args as well as PV pairs
            %
            %               If a style is not specified, then the DEFAULTCLASSNAME.
            %
            %               Ex: {'matlab.FooComponent', 'matlab.BarComponent'}
            %
            %  defaultClassName - a fully qualified MATLAB class to be created when
            %                     the user does not specify a style within STYLES.
            %
            %                     Ex: {'matlab.FooComponent'}
            %
            %  functionName - name of the function actually called by the caller
            %
            %                 Used for error messages.
            %
            %                 Ex: uifcn
            %
            %  userInputs - The user entered arguments that were passed into the
            %             convenience function, as a cell array
            %
            %                       Ex: {'foo', 'SomeProperty', [1 2 3]}
            % 
            %  isComponentContainer - true if the component being created
            %                         subclasses from  matlab.ui.componentcontainer.ComponentContainer
            %
            %                         This is optional                   
            %
            % Outputs:
            %
            %  component - The created component, whose class will match the given
            %              style if specified, and whos properties will be set to all
            %              specified PV pairs.
            %
            %
            % Example: A function that can create 'foo' or 'bar' objects
            %
            %   function obj = uihelper(varargin)
            %
            %     component = matlab.ui.control.internal.createComponentInFamily(...
            %                       {'foo', 'bar'}, ...
            %                       {'matlab.FooComponent', 'matlab.BarComponent'}, ...
            %                       'uifcn',  ...
            %                       varargin{:}
            %                       );                                             
            import matlab.ui.control.internal.model.ComponentCreation;
            
            % Validation / parsing
            %
            % Note we do not use 'arguments' because it was not as
            % performant
            styleNames = creationOptions.styleNames;
            classNames = creationOptions.classNames;
            defaultClassName = creationOptions.defaultClassName;            
            functionName = creationOptions.functionName;
            userInputs = creationOptions.userInputs;
            isComponentContainer = isfield(creationOptions, 'isComponentContainer') && creationOptions.isComponentContainer;
            
            % Use validator to tease apart inputs and throw specific error
            % messages
            [parent, args] = ComponentCreation.getOptionalParent(functionName, userInputs{:});
            [classNameToCreate, style, constructorArgs] = ComponentCreation.getClassNameForStyle(styleNames, classNames, defaultClassName, functionName, args{:});
            
            % create the component
            % g2935943
            %
            % Component Containers will create a default figure if no parent argument is specified.
            % It is important that we always pass in a parent during construction and not set it post construction.
            if(isComponentContainer && ~isempty(parent))
                constructorArgs = [{'Parent', parent}, constructorArgs];
            end
            try
                component = feval(classNameToCreate, constructorArgs{:});
            catch ex
                % Create a style exception only if a style argument appears to have been given.
                % Otherwise, just create a convenience syntax exception.
                if ~isempty(style) || (mod(numel(constructorArgs),2) == 1)
                    if ~isempty(style)
                        badStyle = style;
                    else
                        badStyle = constructorArgs{1};
                    end
                    throw(...
                        createConvenienceSyntaxException(...
                            createStyleException(ex, styleNames, badStyle, functionName),...
                                functionName));
                else
                    throw(...
                        createConvenienceSyntaxException(ex, functionName));
                end
            end
            
            % If the user did not set Parent through PV Pairs, then set it
            % to a new parent
            if(strcmp(component.ParentMode,'auto'))
                % If no parent was given then create a default
                if isempty(parent)
                    parentHandle = ComponentCreation.createDefaultParent(functionName);
                else
                    parentHandle = parent;
                end
                component.Parent = parentHandle;
            end
            
        end

        function bool = isErrorToBePassedThrough(ex)
            bool = matlab.ui.control.internal.model.ComponentCreation.PassthroughErrorLookup.isKey(ex.identifier) || ...
            any(cellfun(@(list)strcmp(list.identifier, 'MATLAB:hg:InvalidProperty'), ex.cause));
        end
        
    end

    properties(Constant, Access = 'private')
        % List of errors not to wrap as a convenience syntax error.
        % These are passed through and allowed to show themselves in the
        % MATLAB command window as they are.
        PassthroughErrors = [...
            "MATLAB:hg:InvalidProperty", ...
            "MATLAB:ui:NumericEditField:invalidValue"
            ];
        PassthroughErrorLookup = dictionary(...
            matlab.ui.control.internal.model.ComponentCreation.PassthroughErrors, ...
            true(1, numel(matlab.ui.control.internal.model.ComponentCreation.PassthroughErrors)));
    end
    
    methods(Static, Access = 'private')
        
        function component = doCreateComponent(classNameToCreate, functionName, varargin)
            
            try
                % Creates the component and passes all PV pairs
                component = feval(classNameToCreate, varargin{:});
                
            catch ex
                throw(createConvenienceSyntaxException(ex, functionName));
            end
        end
        
        function parentHandle = createDefaultParent(functionName)
            % Returns the handle to the parent to use when no
            % parent is specified
            
            if(strcmp(functionName,'uitogglebutton') || strcmp(functionName,'uiradiobutton'))
                % Radio and toggle buttons have to be parented to a button
                % group. When no parent is specified, return a button group
                % created inside an uifigure
                parentHandle = matlab.ui.container.ButtonGroup('Parent', uifigure);                
                    
            elseif(strcmp(functionName,'uitreenode'))
                % TreeNodes have to be parented to a Tree and not directly
                % to a uifigure.
                parentHandle = matlab.ui.container.Tree('Parent', uifigure);
                
            else
                % In all other cases, return an uifigure
                parentHandle = uifigure;
            end
        end

        function [convenienceParent, argsOut] = getOptionalParent(functionName, varargin)
            convenienceParent = [];
            argsOut = varargin;

            if numel(varargin) >= 1
                if isValidParent(varargin{1})
                    convenienceParent = varargin{1};

                    % Remove convenience parent from inputs array
                    argsOut = varargin(2:end);
                elseif ~isempty(varargin) && ~ischar(varargin{1}) && ~isstring(varargin{1})
                    if isobject(varargin{1}) && all(~isvalid(varargin{1}))
                        % First argument was a deleted object.
                        % Throw a more specific error message.
                        % g2019716: Adding the call to 'all' here so non-scalar
                        % convenience parents don't cause unexpected errors.
                        % 'isvalid' returns an array if an array is passed, so it is
                        % necessary to use 'all' to collapse that to a scalar.
                        % The goal is to avoid validating for scalars and allow HG set
                        % to perform the necessary validation for the parent property.
                        
                        messageObj =  message('MATLAB:ui:components:invalidObject', 'Parent');

                        % MnemonicField is last section of error id
                        mnemonicField = 'invalidParent';

                        % Use string from object
                        messageText = getString(messageObj);

                        % Create and throw exception
                        exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(...
                            functionName, mnemonicField, messageText);
                        throw(exceptionObject);
                    elseif ~isstruct(varargin{1})
                        % General case of invalid parent
                        % Check that the argument is not a structure first
                        % because it will be expanded into properties later
                        
                        messageObj =  message('MATLAB:ui:components:invalidParent', 'Parent');

                        % MnemonicField is last section of error id
                        mnemonicField = 'invalidParent';

                        % Use string from object
                        messageText = getString(messageObj);

                        % Create and throw exception
                        exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(...
                            functionName, mnemonicField, messageText);
                        throw(exceptionObject);
                    end
                end
            end
        end

        function [classNameToCreate, style, constructorArgs] = getClassNameForStyle(styles, classNames, defaultClassName, ~, varargin)
            inputs = varargin;
            
            style = '';

            % Create classNameToCreate
            classNameToCreate = defaultClassName;
                
            % Criteria for throwing a style related error:
                    % 1. The first argument is not empty
                    % 2. Component actually has styles
                    % 3. The first argument is a string
            
            if numel(inputs) >= 1 && ~isempty(styles)&& (ischar(inputs{1}) || isstring(inputs{1}))
                % Look for the first argument in the list of possible styles
                if any(strcmpi(styles, inputs{1}))
                    style = inputs{1};

                    % Remove style from inputs array
                    inputs = inputs(2:end);
                end
            end

            if ~isempty(style)
                
                % Find which class the style corresponds to
                matchesStyle = strcmpi(style, styles);
                
                % The first argument matched one of the style strings
                classNameToCreate = classNames{matchesStyle};
                
            end
            
            constructorArgs = inputs;
        end
    end
    
end

function comp = createComponentAndSetParent(classNameToCreate, functionName, constructorArgs, parent, isComponentContainer)
% Create component specified in classNameToCreate using constructorArgs as
% input and set the parent of the component if parent is not empty

import matlab.ui.control.internal.model.ComponentCreation;

% g2935943
%
% Component Containers will create a default figure if no parent argument
% is specified
%
% It is important that we always pass in a parent during construction and
% not set it post construction
if(isComponentContainer && ~isempty(parent))
    constructorArgs = [{'Parent', parent}, constructorArgs];
end

% create the component
comp = ComponentCreation.doCreateComponent(classNameToCreate, functionName, constructorArgs{:});

% Most workflows use graphics SET to set the value of a single PV pair
% which corresponds to the "Parent" property of the component. Using a
% direct property assignment is more performant than using graphics SET in
% these cases
if ~isempty(parent) && isempty(comp.Parent)
    comp.Parent = parent;
end
end

function bool = isValidParent(component)
    % ISVALIDPARENT Determine if the given component is a valid potential parent to others
    %
    % g2019716: Adding the call to 'any' here so non-scalar
    % convenience parents don't cause unexpected errors.
    % 'ishghandle' returns an array if an array is passed, so it is
    % necessary to use 'any' to collapse that to a scalar.
    % The goal is to avoid validating for scalars and allow HG set
    % to perform the necessary validation for the parent property.
    bool = isobject(component) && any(ishghandle(component));
end

function exceptionObject = createConvenienceSyntaxException(originalException, functionName)
    % CREATECONVENIENCESYNTAXEXCEPTION Create an exception object specific to the UI component convenience functions
    %
    % There are several well established generic error messages
    % that are useful to users because they represent a well 
    % known specific issue.  A few of the popular ones are
    % worth looking out for and passing on as is as opposed to
    % the general uifunction error message that just says
    % there's a problem somewhere.
    if startsWith(originalException.identifier, 'MATLAB:InputParser:') && ...
        ~ strcmp(originalException.identifier, 'MATLAB:InputParser:ParamMissingValue')

        messageObj =  message('MATLAB:ui:components:invalidConvenienceSyntax', ...
            functionName);

        % MnemonicField is last section of error id
        mnemonicField = 'invalidConvenienceSyntax';
    
        % Use string from object
        messageText = getString(messageObj);
    
        % Create exception to be thrown by the caller
        exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(functionName, mnemonicField, messageText);
    else
        exceptionObject = originalException;
    end
end

function exceptionObject = createStyleException(originalException, styles, invalidStyle, functionName)
    % CREATESTYLEEXCEPTION Create an exception object that reports an invalid style
    %
    % If the component supports styles and the string specified is not a style match
    % and the string does not match any property names throw error for invalid style.

    % Pass along certain errors. Report other issues as an invalid style error.
    if isempty(styles) || contains(invalidStyle, styles) || ...
            matlab.ui.control.internal.model.ComponentCreation.isErrorToBePassedThrough(originalException)
        exceptionObject = originalException;
    else
        % 'style1'
        initialStyleOptions = ['''', styles{1}, ''''];
        
        if numel(styles) > 2
            % String array of style char arrays
            remainingStyles = string(styles(2:end-1));
            
            % Add comma and single quotes to each style
            % ", 'style2'"         ", 'style3'"
            middleStyles = ', ''' + remainingStyles + '''';
            
            % Concatenate first and middle style options
            initialStyleOptions = [initialStyleOptions, char(middleStyles.join(''))];
        end
        
        lastStyleOption = ['''', styles{end}, ''''];
        messageObj =  message('MATLAB:ui:components:invalidStyleString', ...
            invalidStyle,...
            functionName,...
            initialStyleOptions,...
            lastStyleOption);
        % MnemonicField is last section of error id
        mnemonicField = 'invalidStyleString';
        
        % Use string from object
        messageText = getString(messageObj);

        % Create exception to be thrown by caller
        exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(...
            functionName, mnemonicField, messageText);
    end
end
