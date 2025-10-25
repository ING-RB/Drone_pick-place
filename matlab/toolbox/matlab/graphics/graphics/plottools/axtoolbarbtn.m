function toolbarButton = axtoolbarbtn (varargin)
% AXTOOLBARBTN   Add a custom axes toolbar button.
%   btn = AXTOOLBARBTN(tb) adds a push button to the toolbar 
%   specified by tb and returns the button object.

%   btn = AXTOOLBARBTN(tb, style) adds either a push button or a state 
%   button to the toolbar specified by tb and returns the button object. 
%   For a push button that performs an action with each button press, set 
%   the style to 'push'. For a state button with two states (pressed or 
%   unpressed), set the style to 'state'.
%
%   btn = AXTOOLBARBTN (___, Name, Value) specifies button properties 
%   using one or more name-value pair arguments.
%
%   Example 1: Create a Button
%      % Create a push button, the default style for a button.
%      ax = axes;
%      toolbar = axtoolbar(ax);
%      button = axtoolbartbn(toolbar);
%
%   Example 2: Create a State Button
%      % Create a push button, the default style for a button.
%      ax = axes;
%      toolbar = axtoolbar(ax, 'state');
%      button = axtoolbartbn(toolbar);
%
%   See also AXTOOLBAR.

%   Copyright 2018 The MathWorks, Inc.

% Use push button as the default axestoolbar button
buttonStyle = 'push';
% arg is used to index into the input parameters
arg = 1;
if nargin < 1
    % Create or use current axes
    ax = gca;
    % Use the existing toolbar is available
    if ~isempty(ax.Toolbar)
        % Users should not be allowed to modify default axes toolbar
        if checkIfDefaultToolbar(ax.Toolbar)
            error(message('MATLAB:graphics:axestoolbar:CannotModifyDefaultAxesToolbar'));
        end
        parentToolbar = ax.Toolbar;
    else
        % Create a new axestoolbar and parent it to current axes
        parentToolbar = matlab.ui.controls.AxesToolbar();
        ax.Toolbar = parentToolbar;
    end
else
    % otherwise, use the passed argument and validate if it is a valid
    % axestoolbar handle, otherwise error out
    % axtoolbarbtn(gcf)
    hToolbar = varargin{1};
    if isobject(hToolbar)
        % Validate that obj is a scalar axestoolbar in axtoolbarbtn(obj,...);
        if  length(hToolbar)==1 && ...
                ishghandle(hToolbar) && ...
                isa(handle(hToolbar),'matlab.ui.controls.AxesToolbar')
            parentToolbar = hToolbar;
            arg = 2;
        else
            error(message('MATLAB:graphics:axestoolbar:InvalidAxesToolbar'));
        end
        % axtoolbarbtn({gcf}) when nargin = 1 and not an object
        % axtoolbarbtn([])
    elseif nargin == 1 || isempty(hToolbar)
        error(message('MATLAB:graphics:axestoolbar:InvalidAxesToolbar'));
    else
        % create a new axestoolbar if no parent is specified for example
        % axtoolbarbtn('Visible','on')
        parentToolbar = matlab.ui.controls.AxesToolbar.empty;
    end
    
    % Users should not be allowed to modify default axes toolbar
    if checkIfDefaultToolbar(parentToolbar)
        error(message('MATLAB:graphics:axestoolbar:CannotModifyDefaultAxesToolbar'));
    end
    
    % For even number of arguments, check if the second arg is button style
    % and error out for any invalid value
    if arg > 1 && mod(nargin,2) == 0
        % 1. axtoolbarbtn(axestoolbarObj,'push')
        % 2. axtoolbarbtn(axestoolbarObj,'state','Visible','on')
        if (ischar(varargin{2}) || (isstring(varargin{2}) && isscalar(varargin{2}))) && ...
                (strcmpi(varargin{2},'push') || strcmpi(varargin{2},'state'))
            buttonStyle = varargin{2};
            arg = 3;
        else
            % 1. axtoolbarbtn(axestoolbarObj,'abc')
            % 2. axtoolbarbtn(axestoolbarObj,'abc','Visible','on')
            error(message('MATLAB:graphics:axestoolbar:InvalidToolbarButton'));
        end
    end
end

% Create push/state button based on passed arguments
if strcmpi(buttonStyle,'push')
    toolbarButton = matlab.ui.controls.ToolbarPushButton();
elseif strcmpi(buttonStyle,'state')
    toolbarButton = matlab.ui.controls.ToolbarStateButton();
end

% Add pvpairs which define property/value pairs to the axestoolbar
% Syntax: axtoolbarbtn(AxesToolbar,'Serializable','off').
% check PV pairs
pvPairs = matlab.graphics.internal.convertStringToCharArgs(varargin(arg:end));
% check that every p is a property
for index=1:2:length(pvPairs)
    if ~ischar(pvPairs{index})
        error(message('MATLAB:graphics:axestoolbar:InvalidPropertyName'));
    elseif ~isprop(toolbarButton,pvPairs{index})
        error(message('MATLAB:graphics:axestoolbar:UnknownProperty', pvPairs{index}));
    elseif strcmpi(pvPairs{index},'Parent')
        if ~isa( pvPairs{index+1},'matlab.ui.controls.AxesToolbar')
            error(message('MATLAB:graphics:axestoolbar:InvalidAxesToolbar'));
        else
            % Reassociate parentToolbar to the one passed as a parent to
            % the axes toolbar button.
            parentToolbar =  pvPairs{index+1};
            % Users should not be allowed to modify default axes toolbar
            if checkIfDefaultToolbar(parentToolbar)
                error(message('MATLAB:graphics:axestoolbar:CannotModifyDefaultAxesToolbar'));
            end
        end
    end
end

try
    % Set pvpairs on the toolbar button
    if ~isempty(pvPairs)
        set(toolbarButton,pvPairs{:});
    end
catch ex
    % Delete the toolbar button to cleanup properly
    delete(toolbarButton);
    rethrow(ex);
end

if ~isempty(parentToolbar)
    toolbarButton.Parent = parentToolbar;
end
end

% This function returns true if the parentToolbar is a default axestoolbar.
function isDefaultToolbar = checkIfDefaultToolbar(parentToolbar)
isDefaultToolbar = false;
if ~isempty(parentToolbar)
    if isempty(parentToolbar.Children) && strcmpi(parentToolbar.Serializable,'off')
        isDefaultToolbar = true;
    end
end
end