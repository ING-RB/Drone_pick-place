classdef (Sealed, Hidden, ConstructOnLoad=true) CircularProgressIndicator < ...
        matlab.ui.control.internal.model.AbstractProgressIndicator
    
%CIRCULARPROGRESSINDICATOR Create circular progress indicator component
%   prg = matlab.ui.control.internal.CircularProgressIndicator 
%   creates a circular progress indicator and returns 
%   the CircularProgressIndicator object. No parent is created.
%   
%   prg = matlab.ui.control.internal.CircularProgressIndicator('Parent',parent) 
%   creates a circular progress indicator in the specified parent container.
%   The parent container can be a figure created using the uifigure
%   function, or one of its child containers.
%
%   prg = matlab.ui.control.internal.CircularProgressIndicator(______,Name,Value)
%   specifies CircularProgressIndicator property values using one or more
%   Name,Value pair arguments. Specify name-value pairs with either of the previous syntaxes.
%
%   matlab.ui.control.internal.CircularProgressIndicator properties:
%     CircularProgressIndicator properties:
%       Value            - Progress Value
%       Indeterminate    - Indeterminate progress, specified as 'off' or 'on'
%       ProgressColor    - Color of the progress indicator
%
%    Interactivity properties:
%       Visible          -  CircularProgressIndicator visibility
%       Enable           -  Operational state of CircularProgressIndicator
%       Tooltip          -  Tooltip
%
%     Position properties:
%       Position         - Location and size
%       InnerPosition    - Location and size
%       OuterPosition    - Location and size
%       Layout           - Layout options
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
%   Example 1: Create a circular progress indicator and update its value and color
%      fig = uifigure;
%      prg = matlab.ui.control.internal.CircularProgressIndicator('Parent',fig);
%      % Do some task
%      prg.Value = .5;
%      % Complete task
%      prg.Value = 1;
%      % Change color to green
%      prg.ProgressColor = 'green';
%   
%   Example 2: Create an indeterminate progress indicator
%      fig = uifigure;
%      prg = matlab.ui.control.internal.CircularProgressIndicator('Parent',fig,...
%            'Indeterminate','on');
%
%   Example 3: Create a circular progress indicator and update its value in
%   a loop
%      f = uifigure;
%      prg = matlab.ui.control.internal.CircularProgressIndicator('Parent', f);
%      for i = 1:2000
%         % perform iteration i
%         prg.Value = i/2000;
%         drawnow;
%      end
%
%   See also UIFIGURE, UIPROGRESSDLG, UIIMAGE, PROGRESSINDICATOR

% Copyright 2019 The MathWorks, Inc.
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = CircularProgressIndicator(varargin)
            %
            
            % Do not remove above white space
            % Override the default values
            
            obj = obj@matlab.ui.control.internal.model.AbstractProgressIndicator();
            
            obj.Type = 'uicircularprogressindicator';
            
            % Initialize Layout Properties
            defaultSize = [24, 24];
            obj.PrivateInnerPosition(3:4) = defaultSize;
            obj.PrivateOuterPosition(3:4) = defaultSize;
            obj.AspectRatioLimits = [1 1];
            
            parsePVPairs(obj,  varargin{:});
            
        end
    end
    
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)
        
        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            names = {'Value',...
                'Indeterminate',...
                'ProgressColor',...
                };
            
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            
            str = num2str(obj.Value);
        end
    end
    
end
