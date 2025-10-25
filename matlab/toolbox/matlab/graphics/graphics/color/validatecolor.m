function rgb = validatecolor(colors, allowMultiple)
%VALIDATECOLOR Validate color values
%   RGB = VALIDATECOLOR(color) validates one color and returns the
%   equivalent RGB triplet. Specify color as a color name, hexadecimal
%   color code, or 1-by-3 numeric vector. Use a string scalar or character
%   vector to specify a color name or hexadecimal color code.
%
%   RGB = VALIDATECOLOR(colors, sz) validates one or multiple colors.
%   Specify sz as 'one' to validate a single color or 'multiple' to
%   validate multiple colors. Specify multiple colors as color names,
%   hexadecimal color codes, or an m-by-3 numeric matrix. Use a character
%   vector, cell array of character vectors, or string vector to specify a
%   list of color names or hexadecimal color codes.

%   Copyright 2019-2020 The MathWorks, Inc.

% Check whether to allow one or multiple color specifications.
narginchk(1,2)
if nargin < 2
    % Default to only allowing one color.
    allowMultiple = false;
else
    allowMultiple = validatestring(allowMultiple, ["one","multiple"]);
    allowMultiple = (allowMultiple == "multiple");
end

if ischar(colors) || iscellstr(colors) || isstring(colors)
    % Attempt to convert the colors into RGB triplets.
    [rgb, invalidColors] = matlab.graphics.internal.convertToRGB(colors);
    
    % Check if multiple colors were provided when only one color is allowed.
    if ~allowMultiple && (iscell(colors) || size(rgb, 1) ~= 1)
        error(message('MATLAB:graphics:validatecolor:MultipleColors'))
    end
    
    % Verify that string and cell arrays are vectors.
    if (iscell(colors) || isstring(colors))
        assert(isempty(colors) || isvector(colors), ...
            message('MATLAB:graphics:validatecolor:InvalidStringShape'))
    end
    
    % Check if any of the color names were invalid.
    if ~isempty(invalidColors)
        error(message('MATLAB:graphics:validatecolor:InvalidColorString', invalidColors(1)))
    end
elseif isnumeric(colors)
    % Verify the size of the numeric input.
    if size(colors,2) ~= 3
        if allowMultiple
            error(message('MATLAB:graphics:validatecolor:InvalidNumericShape'))
        else
            error(message('MATLAB:graphics:validatecolor:InvalidTripletShape'))
        end
    end
    
    % Attempt to convert the colors into RGB triplets
    [rgb, invalidColors] = matlab.graphics.internal.convertToRGB(colors);
    
    % Check if multiple colors were specified when only scalar colors are
    % allowed.
    if ~allowMultiple && size(rgb,1) ~= 1
        error(message('MATLAB:graphics:validatecolor:MultipleColors'))
    end
    
    if ~isempty(invalidColors)
        if isfloat(colors) && ~all(colors>=0 & colors<=1, 'all')
            error(message('MATLAB:graphics:validatecolor:OutOfRange'))
        elseif allowMultiple
            error(message('MATLAB:graphics:validatecolor:InvalidColors'))
        else
            error(message('MATLAB:graphics:validatecolor:InvalidColor'))
        end
    end
elseif allowMultiple
    error(message('MATLAB:graphics:validatecolor:InvalidColors'))
else
    error(message('MATLAB:graphics:validatecolor:InvalidColor'))
end
