function c = colororder(target, colors)
%COLORORDER View and set current color order
%   COLORORDER(colors) sets the color order for the current figure. If you
%   set the color order for the figure, then axes in the figure will use
%   the same color order. Specify the color order as a three-column matrix
%   of RGB triplets, the keyword 'default', a cell-array of character
%   vectors, or a string array.
%
%   COLORORDER(name) sets the color order for the current figure
%   using the predefined set of colors specified by name. Valid names
%   are: gem, gem12, glow, glow12, dye, earth, meadow, reef, sail.
%
%   COLORORDER(target, ...) sets the color order for the figure or axes
%   specified by target, instead of for the current figure. When target is
%   a figure, COLORORDER sets the DefaultAxesColorOrder on the figure. When
%   target is an axes, COLORORDER sets the ColorOrder property of the axes.
%
%   colors = COLORORDER returns the color order of the current figure as a
%   three-column matrix of RGB triplets.
%
%   colors = COLORORDER(target) returns the color order for the figure or
%   axes specified by target. When target is a figure, COLORORDER returns
%   the DefaultAxesColorOrder on the figure. When target is an axes,
%   COLORORDER returns the value of the ColorOrder property of the axes.
%
%   See also COLORMAP

%   Copyright 2019-2024 The MathWorks, Inc.

% If output requested, then output the color order.
outputColors = nargout > 0;

% If two inputs provided, assume the second input is the colors.
haveColors = nargin == 2;

% Handle 0 and 1 argument syntaxes.
if nargin == 0
    % colororder()
    target = get(groot,'CurrentFigure');
    if isempty(target)
        % Query the default color order from groot to avoid creating a
        % figure just to get the default value.
        target = groot;
    end
    
    % No colors specified, so query the current color order and always
    % produce an output.
    outputColors = true;
elseif nargin == 1
    if isa(target, 'matlab.graphics.Graphics')
        % colororder(target)
        % No colors specified, so query the current color order and always
        % produce an output.
        outputColors = true;
    else
        % colororder(colors)
        haveColors = true;
        colors = target;
        target = gcf;
    end
end

% Validate that the target is a valid scalar graphics object.
if ~isa(target, 'matlab.graphics.Graphics') || ~isscalar(target)
    error(message('MATLAB:graphics:colororder:InvalidTarget'));
elseif ~isvalid(target)
    error(message('MATLAB:graphics:colororder:DeletedTarget'));
elseif haveColors && isempty(colors)
    % Colororder cannot be empty.
    error(message('MATLAB:graphics:colororder:InvalidColors'));
end

% Convert string color inputs into RGB triplets.
invalidColors = string.empty;
if haveColors && (ischar(colors) || iscellstr(colors) || isstring(colors))
    % Attempt to convert the colors into RGB triplets
    [rgb, invalidColors] = matlab.graphics.internal.convertToRGB(colors);

    if isempty(invalidColors)
        % If all colors were successfully converted, replace the input with
        % the new RGB triplets. Defer throwing an error for now in case the 
        % input is a special keyword (i.e. 'default' or 'factory') or a 
        % named color order.
        colors = rgb;
    end
end

if isscalar(invalidColors) && numel(string(colors)) == 1
    % See if there is a named color order associated with the string.
    try
        colors = orderedcolors(colors);
        invalidColors = string.empty;
    end
elseif ~isempty(invalidColors)
    % Error because multiple colors have been provided and at least one is 
    % invalid, ex: colororder(["red","bad"]) and colororder(["bad","worse"]) 
    error(message('MATLAB:graphics:colororder:InvalidColorString', invalidColors(1)));
end

% If the target is a container, set/get the color order using the default system.
if isa(target, 'matlab.ui.container.Container')
    if haveColors
        try
            % Set the default for axes, polar axes, geographic axes, and
            % map axes. 
            set(target, 'DefaultAxesColorOrder', colors);
            set(target, 'DefaultPolarAxesColorOrder', colors);
            set(target, 'DefaultGeoAxesColorOrder', colors);
            hasMapping = ~isempty(license('inuse', 'map_toolbox'));
            if hasMapping
                set(target, 'DefaultMapAxesColorOrder', colors);
            end
            
            % Set the default for the Mode to be manual to reflect that the 
            % user is requesting a specific color order. Use the special keywords
            % for the Mode in those cases.
            modeDefaultValue = 'manual';
            if matlab.graphics.internal.isCharOrString(colors) && ...
                    ismember(colors, ["default","factory","remove"])
                modeDefaultValue = colors;
            end
            set(target, 'DefaultAxesColorOrderMode', modeDefaultValue);
            set(target, 'DefaultPolarAxesColorOrderMode', modeDefaultValue);
            set(target, 'DefaultGeoAxesColorOrderMode', modeDefaultValue);
            if hasMapping
                set(target, 'DefaultMapAxesColorOrderMode', modeDefaultValue);
            end

            % Call colororder method on objects
            comethod = findall(target, '-isa', 'matlab.graphics.chartcontainer.mixin.ColorOrderMixin');
            for i = 1:numel(comethod)
                comethod(i).validateAndSetColorOrderInternal(colors);
            end
            
            % Find all the children that have ColorOrder properties and set
            % their color order.
            co = findall(target, '-property', 'ColorOrder');
            co = setdiff(co, comethod); 
            set(co, 'ColorOrder', colors);
        catch err
            throwInvalidColorsError(err, invalidColors);
        end
    end
    if outputColors
        c = get(target, 'DefaultAxesColorOrder');
    end
elseif isprop(target, 'ColorOrder')
    if haveColors
        try
        % Use the set command so the 'default' and 'factory' keywords work
        % and errors if is is an invalid color specification.
        set(target, 'ColorOrder', colors)
        catch err
            throwInvalidColorsError(err, invalidColors);
        end
    end
    if outputColors
        c = target.ColorOrder;
    end
elseif isa(target, 'matlab.graphics.chartcontainer.mixin.ColorOrderMixin')
    if haveColors
        try
            target.validateAndSetColorOrderInternal(colors);
        catch err
            throwInvalidColorsError(err, invalidColors);
        end
    end
    if outputColors
        c = target.getColorOrder();
    end
else
    % Invalid target
    error(message('MATLAB:graphics:colororder:InvalidTarget'));
end
end

function throwInvalidColorsError(err, invalidColors)
    if ~isempty(invalidColors)
        throwAsCaller(MException('MATLAB:graphics:colororder:InvalidColorString',...
            message('MATLAB:graphics:colororder:InvalidColorString', invalidColors(1))));
    elseif strcmp(err.identifier, 'MATLAB:hg:shaped_arrays:ColorOrderType')
        throwAsCaller(MException('MATLAB:graphics:colororder:InvalidColors',...
            message('MATLAB:graphics:colororder:InvalidColors')));
    end
    throwAsCaller(err);
end