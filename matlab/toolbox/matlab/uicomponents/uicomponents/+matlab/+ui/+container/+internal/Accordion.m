classdef (Sealed, Hidden, ConstructOnLoad=true) Accordion < ...
        matlab.ui.container.internal.model.ContainerModel & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.NonserializableComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent & ...
        matlab.ui.internal.mixin.Scrollable
%ACCORDION Create accordion container
%   Accordion is a container that stacks accordion panels vertically. 
%   You can collapse or expand accordion panels that are in an accordion
%   container.
%
%   acc = matlab.ui.container.internal.Accordion creates an accordion and 
%   returns the Accordion object. No parent is created.
%
%   acc = matlab.ui.container.internal.Accordion('Parent',parent) creates 
%   an accordion in the specified parent container. The parent container
%   must be a GridLayout object. 
%
%   acc = matlab.ui.container.internal.Accordion(______,Name,Value) 
%   specifies Accordion property values using one or more Name,Value pair 
%   arguments. Use this option with any of the input argument combinations 
%   in the previous syntaxes.
%
%
%   matlab.ui.container.internal.Accordion properties:
%     Interactivity properties:
%       Visible          -  Visibility
%
%     Position properties:
%       Layout           - Layout options
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
%   matlab.ui.container.internal.Accordion supported functions:
%      collapse          - Collapse all the children of accordion
%      expand            - Expand all the children of accordion
%
%
%
%   Example: Create an Accordion and Accordion Panel
%     f = uifigure;
%     g = uigridlayout(f,[1,1]);
% 
%     acc = matlab.ui.container.internal.Accordion('Parent',g);
%     ap = matlab.ui.container.internal.AccordionPanel('Parent',acc);
% 
%     g1 = uigridlayout(ap);
%     g1.ColumnWidth = {'fit',200};
%     g1.RowHeight = {'fit','fit'};
% 
%     uilabel(g1,'Text','First name');
%     uieditfield(g1);
% 
%     uilabel(g1,'Text','Last name');
%     uieditfield(g1);
%
%     ap.collapse();
%
%
%   See also uifigure, matlab.ui.container.internal.AccordionPanel,
%   uigridlayout, uitabgroup

% Copyright 2019 The MathWorks, Inc.

    methods
        function obj = Accordion(varargin)
            %
                
            % Do not remove above white space
            obj.Type = 'uiaccordion';

            parsePVPairs(obj,  varargin{:});

            obj.ValidateChildFcn = @validateChild;
        end
        
        function expand(obj)
            %EXPAND - Expand all accordion panels parented to the
            % accordion
            %
            %    See also COLLAPSE, matlab.ui.container.internal.AccordionPanel/expand
            
            for k = 1:length(obj.Children)
                obj.Children(k).expand();
            end
        end
        
        function collapse(obj)
            %COLLAPSE - Collapse all accordion panels parented to the
            % accordion
            %
            %    See also EXPAND, matlab.ui.container.internal.AccordionPanel/collapse
            
            for k = 1:length(obj.Children)
                obj.Children(k).collapse();
            end
        end

        function scroll(this, varargin)
            scroll@matlab.ui.internal.mixin.Scrollable(this, varargin{:});
        end
    end

    methods(Access = protected)
        function validateChild(obj, newChild)
            % Validator for 'Child'
            %
            % Can be extended / overriden to provide additional validation
            
            % Error Checking
            %
            % A valid child is AccordionPanel
            
            % Only validate if the value is non empty
            %
            % Empty values are acceptible for not having a parent
            if(~isempty(newChild))
                
                if ~(isa(newChild, 'matlab.ui.container.internal.AccordionPanel'))
 
                    childClassName = matlab.ui.control.internal.model.PropertyHandling.getComponentClassName(newChild);
                    messageObj = message('MATLAB:ui:containers:invalidAccordionChild', ...
                        'Accordion', 'Parent', childClassName);
                    
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
        
        function validateParentAndState(obj, newParent)
            % Validator for 'Parent'
            %
            % Can be extended / overriden to provide additional validation

            % Error Checking
            %
            % A valid parent is one of:
            % - GridLayout 
            % - empty []

            % Only validate if the value is non empty
            %
            % Empty values are acceptible for not having a parent
            if(~isempty(newParent))

                if ~(isa(newParent, 'matlab.ui.container.GridLayout'))

                    messageObj = message('MATLAB:ui:components:invalidClass', ...
                        'Parent', 'GridLayout');

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
            
            names = {'Parent',...
                'Children'};
            
        end
        
        function str = getComponentDescriptiveLabel(~)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            
            
            % There's no strong property in Accordion representing the visual
            % for the component. 
            str = '';
        end
    end

end