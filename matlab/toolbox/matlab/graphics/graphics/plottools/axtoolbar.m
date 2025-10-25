function [axesToolbar,toolbarButtons] = axtoolbar (varargin)
% AXTOOLBAR  Creates an axes toolbar for customization.
%
%    toolbar = AXTOOLBAR (ax) replaces the toolbar
%    for the specified axes with an empty toolbar and returns the
%    AxesToolbar object created
%
%    [toolbar, buttons] = AXTOOLBAR (ax, buttons) adds the specified
%    buttons to the toolbar. For example, {'pan','restoreview'} adds a
%    button to pan and a button to restore the original view.
%
%    [toolbar, buttons] = AXTOOLBAR (___, Name, Value) specifies toolbar
%    properties using one or more name-value pair arguments.
%
%   Example 1: Create an axestoolbar with no buttons
%      ax = axes;
%      toolbar = axtoolbar(ax);
%
%   Example 2: Create an axestoolbar with pan and restoreview
%      ax = axes;
%      toolbar = axtoolbar(ax, {'restoreview', 'pan'});
%
%   Example 3: Create a default axestoolbar
%      ax = axes;
%      toolbar = axtoolbar(ax, 'default');
%
%   Example 3: Create an axestoolbar with a custom button
%      ax = axes;
%      toolbar = axtoolbar(ax, 'default');
%      btn = axtoolbarbtn(toolbar, 'state', 'Icon', 'myIcon.png');
%
% See also AXTOOLBARBTN.

%   Copyright 2018-2024 The MathWorks, Inc.

% Create empty vector of toolbar buttons
toolbarButtons = matlab.graphics.controls.AxesToolbarButton.empty(0,1);

% Pre-allocate empty graphics handle for the parent axes
parentAxes = matlab.graphics.Graphics.empty;

% If no arguments are passed, create/use the gca
% axtoolbar()
if nargin < 1
    parentAxes = gca;
    % Associate the axes with the axes toolbar
    axesToolbar = parentAxes.Toolbar_I;
    if isempty(axesToolbar)
        % Construct axestoolbar using the class constructor
        axesToolbar = matlab.ui.controls.AxesToolbar();
    end

    deparentToolbarButtons = deparentAxesToolbarChildren(axesToolbar);
else
    % Arg is used to index into the input parameters
    arg = 1;
    hAxes = varargin{1};
    % Get axes from the argument parameter
    if isobject(hAxes) && ~isa(hAxes, "string")
        % Validate that obj is a scalar axes in axtoolbar(obj,...);
        if  isscalar(hAxes) && ...
                ishghandle(hAxes) && ...
                isa(handle(hAxes),'matlab.graphics.axis.AbstractAxes') ||...
                isa(handle(hAxes),'matlab.graphics.layout.Layout')
            parentAxes = handle(hAxes);
            arg = 2;
        else
            % We dont want to modify Charts
            error(message('MATLAB:graphics:axestoolbar:InvalidParentAxes'));
        end
        % Syntax: axtoolbar({gcf}) where nargin=1, make sure is a valid axes handle
    elseif isempty(hAxes)
        error(message('MATLAB:graphics:axestoolbar:InvalidParentAxes'));
    end

    % If parentAxes is empty at this point, create/use gca
    % Syntax: axtoolbar('Visible','on')
    if isempty(parentAxes)
        parentAxes = gca;
    end

    % Get the enumerated list of axestoolbar button types in the order in
    % which they should be created
    % This contains the list of axes toolbar buttons that needs to be
    % created based on user parameters
    [~, buttonTypesEnum] = enumeration('matlab.graphics.controls.internal.ToolbarValidator');
    isButtonParameterSpecified = false;

    % For even number of arguments (where axes is the first specified argument),
    % check if the second arg is button style. For odd number of arguments
    % and axes is not specified as the first argument, we validate for the
    % button style and error out for any invalid value.
    % 1. axtoolbar(gca,'default' or {'zoomin','pan','zoomout','reset','brush'})
    % 2. axtoolbar(gca,'default',pvpairs) or axtoolbar('default',pvpairs)
    % 3. axtoolbar('default')
    if (arg > 1 && mod(nargin,2) == 0) || (arg == 1 && mod(nargin,2) ~= 0)
        % Convert all the strings to characters because strcmp function
        % does not accept cell array of strings g1754206
        buttonArgs = matlab.graphics.internal.convertStringToCharArgs(varargin{arg});
        if iscellstr(buttonArgs) || ischar(buttonArgs) %#ok<ISCLSTR>
            % axtoolbar(gca,'pan') or axtoolbar(gca,{'pan','zoomin'},pvpairs)
            % Also, check if default is present as one of the cellstr
            try
                buttonPos = matlab.graphics.controls.internal.ToolbarValidator.validateButtonArgs(buttonArgs, parentAxes);
            catch ex
                error(ex.identifier,ex.message);
            end
            isButtonParameterSpecified = true;
            arg = arg+1;
        else
            % Invalid values of button args
            % axtoolbar(gca,hObj) or axtoolbar(gca,{hObj},pvpairs)
            % If all buttons are not the member of default button types
            % axtoolbar(gca,'zoom1') or axtoolbar(gca,{'pan1','zoomaway},pvpairs)
            if iscell(buttonArgs)
                error(message('MATLAB:graphics:axestoolbar:InvalidButtonEnum'));
            else
                error(message('MATLAB:graphics:axestoolbar:InvalidButtonType', string(buttonArgs)));
            end
        end
    end

    axesToolbar = matlab.ui.controls.AxesToolbar();

    % Validate pvpairs which define property/value pairs to the axestoolbar
    % Syntax: axtoolbar(gca,'Serializable','off') or axtoolbar('Serializable','off')
    % or axtoolbar(gca,'default','Serializable','off')
    % check PV pairs
    pvPairs = matlab.graphics.internal.convertStringToCharArgs(varargin(arg:end));

    % args must be an even number of string,value pairs.
    % check that every p is a property
    numPvPairs = length(pvPairs);
    for index=1:2:numPvPairs
        if ~ischar(pvPairs{index})
            error(message('MATLAB:graphics:axestoolbar:InvalidPropertyName'));
        elseif ~isprop(axesToolbar,pvPairs{index})
            error(message('MATLAB:graphics:axestoolbar:UnknownProperty', pvPairs{index}));
        elseif strcmpi(pvPairs{index},'Parent')
            if ~isa(pvPairs{index+1},'matlab.graphics.axis.AbstractAxes')
                error(message('MATLAB:graphics:axestoolbar:InvalidParentAxes'));
            else
                % Reassociate parentAxes. The last input should win,
                % so the name/value pair should win over the first input argument.
                % For example: axtoolbar(ax1,'Parent',ax2)
                % ax2 should win over ax1
                parentAxes = pvPairs{index+1};
            end
        end
    end

    % If there is an existing axes toolbar, we need to be able to
    % restore it in case of any error. In the code below, we may
    % replace the existing toolbar buttons. Rather than deleting the
    % existing toolbar buttons, just de-parent them so that we can restore
    % them if there is any error.
    deparentToolbarButtons = deparentAxesToolbarChildren(axesToolbar);

    try
        % Set any pv pairs on the axestoolbar
        if ~isempty(pvPairs)
            set(axesToolbar,pvPairs{:});
        end
    catch ex
        % Ensure toolbar buttons are restored in the right order when there
        % is an error, so that we do not leave the axestoolbar in a bad
        % state.
        for i = numel(deparentToolbarButtons):-1:1
            deparentToolbarButtons(i).Parent = axesToolbar;
        end
        % Rethrow the error caused as a result of setting pvpairs
        rethrow(ex);
    end

    % The logic below ensures that the toolbar buttons are created in the
    % same order as specified in defaultButtonTypes
    % If user-defined parameters belong to enumeration
    if isButtonParameterSpecified
        % If 'default' is present as one of the button arguments,
        % create all default toolbar buttons
        % axtoolbar(gca,{'pan,'default'});
        if any(strcmpi(buttonArgs,matlab.graphics.controls.internal.ToolbarValidator.default))
            % Ignore all other parameters to just create the default toolbar
            axesToolbarButtons = matlab.graphics.controls.ToolbarController.createToolbarButton(matlab.graphics.controls.internal.ToolbarValidator.default, parentAxes);
        else
            sortedButtonPos = unique(buttonPos);
            % Pre-Allocate memory for axestoolbarButtons
            axesToolbarButtons = repmat(matlab.graphics.GraphicsPlaceholder,numel(sortedButtonPos),1);
            emptyButtons = ones(numel(sortedButtonPos),1);

            % Create the specified toolbar buttons in the right order
            % axtoolbar(gca,{'pan,'zoomin'});
            for index=1:numel(sortedButtonPos)
                btn = matlab.graphics.controls.ToolbarController.createToolbarButton(buttonTypesEnum(sortedButtonPos(index)), parentAxes);
                if ~isempty(btn)
                    emptyButtons(index) = 0;
                    axesToolbarButtons(index) = btn;
                end
            end

            axesToolbarButtons = axesToolbarButtons(emptyButtons == 0);
        end

        for i=1:numel(axesToolbarButtons)
            axesToolbarButtons(i).Parent = axesToolbar;
        end

        % Return axestoolbar along with the non-empty buttons
        toolbarButtons = axesToolbarButtons;
    end
end

% It is important to set the serializable property of the axestoolbar
% to on for the customized axestoolbar
delete(deparentToolbarButtons);
axesToolbar.Serializable = 'on';

% If I have recreated a new axestoolbar here, I need to delete the old one
if isempty(axesToolbar.Parent)
    delete(parentAxes.Toolbar_I);
end

parentAxes.Toolbar = axesToolbar;
axesToolbar.Parent = parentAxes;

end

% This function ensures that if we are using an existing default axestoolbar;
% any toolbar buttons on the default axestoolbar are cleared.
% Also, set the serializable property to on.
function deparentToolbarButtons = deparentAxesToolbarChildren(axesToolbar)
% De-parent all the default toolbar buttons
deparentToolbarButtons = allchild(axesToolbar);
set(deparentToolbarButtons,'Parent',[]);
end
