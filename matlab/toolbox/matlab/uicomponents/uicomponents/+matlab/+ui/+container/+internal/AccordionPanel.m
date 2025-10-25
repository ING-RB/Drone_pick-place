classdef (Sealed, Hidden, ConstructOnLoad=true) AccordionPanel < ...
        matlab.ui.container.internal.model.ContainerModel &...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.NonserializableComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.container.internal.model.mixin.BackgroundColorableContainer &...
        matlab.ui.control.internal.model.mixin.FocusableComponent
%ACCORDIONPANEL Create accordion panel container
%   AccordionPanel is a container that stacks vertically in an Accordion 
%   object and can be collapsed or expanded. To add UI components to the 
%   accordion panel, first add a GridLayout object to it. Then, add UI 
%   components to the GridLayout object.
%   
%   ap = matlab.ui.container.internal.AccordionPanel creates an accordion panel and 
%   returns the AccordionPanel object. No parent is created.
%
%   ap = matlab.ui.container.internal.AccordionPanel('Parent',parent) creates 
%   an accordion panel in the specified parent container. The parent 
%   container must be an Accordion object.
%
%   ap = matlab.ui.container.internal.AccordionPanel(______,Name,Value) 
%   specifies AccordionPanel property values using one or more Name,Value pair 
%   arguments. Use this option with any of the input argument combinations 
%   in the previous syntaxes.
%
%
%   matlab.ui.container.internal.AccordionPanel properties:
%     Header properties:
%       Title     - Title
%       Collapsed - Whether the accordion panel is collapsed
%
%     Interactivity properties:
%       Visible          -  Visibility
%
%     Callback properties:
%       CreateFcn              - Creation function
%       DeleteFcn              - Deletion function
%
%     Callback execution control properties:
%       Interruptible    - Callback interruption
%       BusyAction       - Callback queuing
%       BeingDeleted     - Deletion status
%
%     Parent/child properties:
%       Parent           - Parent container
%       Children         - Children
%       HandleVisibility - Visibility of object handle
%
%     Identifier properties:
%       Type             - Type of graphics object
%       Tag              - Object identifier
%       UserData         - User data
%
%   matlab.ui.container.internal.AccordionPanel supported functions:
%      collapse          - Collapse accordion panel
%      expand            - Expand accordion panel
%
%
%
%   See also uifigure, matlab.ui.container.internal.Accordion, uigridlayout

% Copyright 2019-2023 The MathWorks, Inc.

    properties(Dependent, AbortSet)
        %Title - Title, specified as a character vector, string scalar, or categorical scalar
        Title = 'Accordion Panel';
        
        %Collapsed - Whether the accordion panel is collapsed or not, specified as a logical scalar
        Collapsed logical = false;
    end

    properties(Transient,...
            SetAccess = {?matlab.ui.container.internal.controller.AccordionPanelController},...
            GetAccess = public)
        Position matlab.internal.datatype.matlab.graphics.datatype.Position = [1, 1, 100, 100];
    end

    properties(Access = 'private')
        PrivateTitle =  'Accordion Panel';
        PrivateCollapsed logical = false;
    end

    properties(Access='protected', NonCopyable)
        PrivateCollapsedChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    properties(NonCopyable, Dependent, AbortSet)
        CollapsedChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})
        CollapsedChanged
    end

    methods

        function obj = AccordionPanel(varargin)
            %
                
            % Do not remove above white space
            % Defaults
            obj.FontWeight = 'bold';
            obj.BackgroundColor_I = obj.DefaultGray;

            obj.Type = 'uiaccordionpanel';
            parsePVPairs(obj,  varargin{:});
            obj.attachCallbackToEvent('CollapsedChanged', 'PrivateCollapsedChangedFcn');

            obj.ValidateChildFcn = @validateChild;
        end

        function set.Title(obj, value)
            % Error Checking
            try
                newValue = matlab.ui.control.internal.model.PropertyHandling.validateAnnotationText(value);
            catch  ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidAnnotationTextValue', ...
                    'Title');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidTitle';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            obj.PrivateTitle = newValue;
            obj.markPropertiesDirty({'Title'});
        end

        function set.Position(obj, val)
            obj.Position = val;
        end
        
        function set.CollapsedChangedFcn(obj, val)
            obj.PrivateCollapsedChangedFcn = val; 
            obj.markPropertiesDirty({'CollapsedChangedFcn'});
        end
        
        function val = get.CollapsedChangedFcn(obj)
            val = obj.PrivateCollapsedChangedFcn; 
        end

        function value = get.Title(obj)
            value = obj.PrivateTitle;
        end

        function set.Collapsed(obj, value)
            
            % Error Checking
            try
                newValue = matlab.ui.control.internal.model.PropertyHandling.validateLogicalScalar(value);
                
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidBooleanProperty', ...
                    'Collapsed');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidCollapsed';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            obj.PrivateCollapsed = newValue;
            obj.markPropertiesDirty({'Collapsed'});
        end

        function value = get.Collapsed(obj)
            value = obj.PrivateCollapsed;
        end
        
        function expand(obj)
            %EXPAND - Expand accordion panel
            %
            %    See also COLLAPSE, matlab.ui.container.internal.Accordion/expand
            
            obj.Collapsed = false;
        end
        
        function collapse(obj)
            %COLLAPSE - Collapse accordion panel
            %
            %    See also EXPAND, matlab.ui.container.internal.Accordion/collapse
            
            obj.Collapsed = true;
        end
    end

    methods(Access = 'protected')

        function validateParentAndState(obj, newParent)
            % Validator for 'Parent'
            %
            % Can be extended / overriden to provide additional validation

            % Error Checking
            %
            % A valid parent is one of:
            % - a parenting component
            % - empty []

            % Only validate if the value is non empty
            %
            % Empty values are acceptible for not having a parent
            if(~isempty(newParent))

                if ~(isa(newParent, 'matlab.ui.container.internal.Accordion'))

                    messageObj = message('MATLAB:ui:containers:invalidAccordionPanelParent', ...
                        'Parent', 'Accordion');

                    % MnemonicField is last section of error id
                    mnemonicField = 'invalidParent';

                    % Use string from object
                    messageText = getString(messageObj);

                    % Create and throw exception
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                    throw(exceptionObject);

                end
            end
        end
        
        function validateChild(obj, newChild)
            % Validator for 'Child'
            %
            % Can be extended / overriden to provide additional validation
            
            % Error Checking
            %
            % Valid child: GridLayout
            
            % Only validate if the value is non empty
            %
            % Empty values are acceptible for not having a parent
            if(~isempty(newChild))
                
                if ~(isa(newChild, 'matlab.ui.container.GridLayout'))
 
                    objClassName = matlab.ui.control.internal.model.PropertyHandling.getComponentClassName(obj);
                    childClassName = matlab.ui.control.internal.model.PropertyHandling.getComponentClassName(newChild);
                    
                    messageObj = message('MATLAB:ui:components:invalidParentOfComponent', ...
                        objClassName, childClassName);
                    
                    % MnemonicField is last section of error id
                    mnemonicField = 'invalidParent';
                    
                    % Use string from object
                    messageText = getString(messageObj);
                    
                    % Create and throw exception
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                    throwAsCaller(exceptionObject);
                   
                end
            end            
        end
    end
    
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)
        
        function names = getPropertyGroupNames(~)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            names = {'Title',...
                'Collapsed',...
                'CollapsedChangedFcn'};
            
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            
            
            % There's no strong property in Accordion representing the visual
            % for the component. 
            str = obj.Title;
        end
    end

    % ---------------------------------------------------------------------
    % Theme Method Overrides
    % ---------------------------------------------------------------------
    methods (Hidden, Access='protected', Static)
        function map = getThemeMap
            % GETTHEMEMAP - This method returns a struct describing the 
            % relationship between class properties and theme attributes.
            
            %          Theme Prop   Theme Attribute

            map = getThemeMap@matlab.ui.container.internal.model.mixin.BackgroundColorableContainer();
            map.FontColor = '--mw-color-primary';
        end
    end

    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 
            saveobj(obj);

            % sObj is the serialization content for obj 
            modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj, obj);
            modifyOutgoingSerializationContent@matlab.ui.container.internal.model.mixin.BackgroundColorableContainer(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
           modifyIncomingSerializationContent@matlab.ui.container.internal.model.mixin.BackgroundColorableContainer(sObj);
        end 

    end
    % ---------------------------------------------------------------------
    % Functions accessible by the controller
    % ---------------------------------------------------------------------
    methods (Access = {...
            ?matlab.ui.container.internal.controller.AccordionPanelController
            })
        
        function setPositionFromClient(obj, newPosition)
            obj.Position = newPosition;
        end
        
    end
end
