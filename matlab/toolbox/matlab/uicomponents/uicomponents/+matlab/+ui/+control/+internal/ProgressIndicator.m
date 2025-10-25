classdef (Sealed, Hidden, ConstructOnLoad=true) ProgressIndicator < ...
        matlab.ui.control.internal.model.AbstractProgressIndicator
    
%PROGRESSINDICATOR Create linear progress indicator component
%   prg = matlab.ui.control.internal.ProgressIndicator 
%   creates a linear progress indicator and returns 
%   the ProgressIndicator object. No parent is created.
%   
%   prg = matlab.ui.control.internal.ProgressIndicator('Parent',parent) 
%   creates a linear progress indicator in the specified parent container.
%   The parent container can be a figure created using the uifigure
%   function, or one of its child containers.
%
%   prg = matlab.ui.control.internal.ProgressIndicator(______,Name,Value)
%   specifies ProgressIndicator property values using one or more
%   Name,Value pair arguments. Specify name-value pairs with either of the previous syntaxes.
%
%   matlab.ui.control.internal.ProgressIndicator properties:
%     ProgressIndicator properties:
%       Value            - Progress Value
%       Indeterminate    - Indeterminate progress, specified as 'off' or 'on'
%       ProgressColor    - Color of the progress indicator
%
%    Interactivity properties:
%       Visible          -  ProgressIndicator visibility
%       Enable           -  Operational state of ProgressIndicator
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
%   Example 1: Create a linear progress indicator and update its value and color
%      fig = uifigure;
%      prg = matlab.ui.control.internal.ProgressIndicator('Parent',fig);
%      % Do some task
%      prg.Value = .5;
%      % Complete task
%      prg.Value = 1;
%      % Change color to green
%      prg.ProgressColor = 'green';
%   
%   Example 2: Create an indeterminate progress indicator
%      fig = uifigure;
%      prg = matlab.ui.control.internal.ProgressIndicator('Parent',fig,...
%                          'Indeterminate','on');
%
%   Example 3: Create a progress indicator and update its value in a loop
%      f = uifigure;
%      prg = matlab.ui.control.internal.ProgressIndicator('Parent', f);
%      for i = 1:2000
%         % perform iteration i
%         prg.Value = i/2000;
%         drawnow;
%      end
%
%   See also UIFIGURE, UIPROGRESSDLG, UIIMAGE, CIRCULARPROGRESSINDICATOR

% Copyright 2019 The MathWorks, Inc.
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = ProgressIndicator(varargin)
            %
            
            % Do not remove above white space
            % Override the default values
            
            obj = obj@matlab.ui.control.internal.model.AbstractProgressIndicator();
            
            obj.Type = 'uiprogressindicator';
            
            % Initialize Layout Properties
            defaultSize = [100, 6];
            obj.PrivateInnerPosition(3:4) = defaultSize;
            obj.PrivateOuterPosition(3:4) = defaultSize;
            
            % Override the default values
            obj.IsSizeFixed = [false true];
            
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
