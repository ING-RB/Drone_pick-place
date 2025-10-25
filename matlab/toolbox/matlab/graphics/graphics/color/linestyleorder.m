function lso = linestyleorder(varargin)
%

%   Copyright 2023-2024 The MathWorks, Inc.

% If output is requested, output the line style order.

[target,linestyles,cyclingmethod,modeDefaultValue] = parseArguments(varargin{:});
hasLineStyles = ~isempty(linestyles);
outputLineStyles = nargout > 0 || ~hasLineStyles;

% If the target is a container, set/get the line style order using the
% default system.
if isa(target, 'matlab.ui.container.Container')
    if hasLineStyles
        hasMapping = ~isempty(license('inuse', 'map_toolbox'));

        % Set the default for axes, polar axes, geographic axes, and map axes.
        setDefaultProp(target, 'LineStyleOrder', linestyles, hasMapping);
        setDefaultProp(target, 'LineStyleCyclingMethod', cyclingmethod, hasMapping);

        % Set the default for the Mode to be manual to reflect that the
        % user is requesting a specific line style order. Use the
        % special keyword for the Mode in these cases.
        setDefaultProp(target, 'LineStyleOrderMode', modeDefaultValue, hasMapping);
        setDefaultProp(target, 'LineStyleCyclingMethodMode', modeDefaultValue, hasMapping);

        % Find all the children that have LineStyleOrder properties and
        % set their line style orders.
        lsoChildren = findall(target, '-property', 'LineStyleOrder');
        set(lsoChildren, 'LineStyleOrder', linestyles);
        lscmChildren = findall(target, '-property', 'LineStyleCyclingMethod');
        set(lscmChildren, 'LineStyleCyclingMethod', cyclingmethod);
    end
    if outputLineStyles
        lso = get(target, 'DefaultAxesLineStyleOrder');
    end
elseif isprop(target, 'LineStyleOrder')
    if hasLineStyles
        set(target, 'LineStyleOrder', linestyles)
        set(target, 'LineStyleCyclingMethod', cyclingmethod);
    end
    if outputLineStyles
        lso = target.LineStyleOrder;
    end
end
end

function setDefaultProp(target, propName, propValue, hasMapping)
% Set the default for axes, polar axes, geographic axes, and map axes.
set(target, ['DefaultAxes' propName], propValue);
set(target, ['DefaultPolarAxes' propName], propValue);
set(target, ['DefaultGeoAxes' propName], propValue);
if hasMapping
    set(target, ['DefaultMapAxes' propName], propValue);
end
end

function [target,linestyles,cyclingmethod,modeDefaultValue] = parseArguments(varargin)
% Check for optional graphics object as first argument, separate if true.
[target, args] = matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent(varargin);
targetEmpty = isempty(target);
% Check number of left over arguments.
numArgs = numel(args);
if numArgs > 2
    error(message('MATLAB:TooManyInputs'));
end

%% Validate that the target is a valid scalar graphics object.
if ~targetEmpty
    if isa(target, 'matlab.graphics.Graphics') && any(~isvalid(target))
        error(message('MATLAB:graphics:colororder:DeletedTarget'));
    elseif ~isscalar(target) || ~(isa(target, 'matlab.ui.container.Container') || isprop(target,'LineStyleOrder'))
        error(message('MATLAB:graphics:colororder:InvalidTarget'));
    end
end

% Default for outputs.
linestyles = {}; 
cyclingmethod = {}; 
modeDefaultValue = 'manual';

if numArgs
    linestyles = args{1};
    if isempty(linestyles)
        % linestyles cannot be empty.
        error(message('MATLAB:graphics:colororder:InvalidLineStyles'));
    end
    if numArgs == 1
        % Cycling method is 'withcolor' if not specified.
        cyclingmethod = 'withcolor';
    else
        cyclingmethod = args{2};
    end
    if matlab.graphics.internal.isCharOrString(linestyles)
        % Check for any keywords.
        if ismember(linestyles, ["default", "factory", "remove"])
            cyclingmethod = linestyles;
            modeDefaultValue = linestyles;
        elseif strcmpi(linestyles, 'mixedmarkers')
            linestyles = {'-o', '-*', '-^', '-x', '-s', '-p', '-d'};
        elseif strcmpi(linestyles, 'mixedstyles')
            linestyles = {'-', '--', '-.', ':'};
        else % Validate line style
            try hgcastvalue('matlab.graphics.datatype.NLineStyles', linestyles);
            catch err
                throwAsCaller(MException(message('MATLAB:graphics:colororder:InvalidLineStyles')));
            end
        end
    else % Validate line styles
        try 
            hgcastvalue('matlab.graphics.datatype.NLineStyles', linestyles);
        catch err
            throwAsCaller(MException(message('MATLAB:graphics:colororder:InvalidLineStyles')));
        end
    end

    if targetEmpty
        target = gcf;
    end
elseif targetEmpty
    % linestyleorder(), query the line style order.
    target = get(groot, 'CurrentFigure');
    if isempty(target)
        % Query the default line style order from groot to avoid creating a
        % figure just to get the default value.
        target = groot;
    end
end
end