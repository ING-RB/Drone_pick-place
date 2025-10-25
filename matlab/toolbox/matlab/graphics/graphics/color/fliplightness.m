function rgbflip = fliplightness(rgb)
%

%   Copyright 2024 The MathWorks, Inc.

arguments
    rgb
end

inputdata.class = class(rgb);
inputdata.isnumeric = isnumeric(rgb);
inputdata.isinteger = isinteger(rgb);
inputdata.ishex = ishex(rgb);
inputdata.size = size(rgb);

rgb = convertToRGBArray(rgb);
rgb = matlab.graphics.internal.LightnessConverter.convertLightness(rgb);
rgbflip = preserveSizeAndClass(rgb, inputdata);
end

function TF = ishex(rgb)
% Returns true if all values in RGB are hex codes.
% Otherwise returns false. Hex codes are loosely defined here as starting
% with a hash character, ignoring any leading whitespace.  validatecolor
% will provide more detailed error handling.
if ischar(rgb)||isstring(rgb)||iscellstr(rgb)
    if ischar(rgb) && height(rgb)>1
        % startsWith won't accept char arrays but validatecolors will.
        rgb = string(rgb);
    end
    TF = all(startsWith(rgb, regexpPattern('^\s*#')),'all');
else
    TF = false;
end
end

function rgb = convertToRGBArray(rgb)
% Validate rgb inputs and convert inputs to a double mx3 sRGB matrix [0,1].
if isstring(rgb) || iscellstr(rgb)
    rgb = rgb(:);
elseif isnumeric(rgb)
    % only mx3 or mxnx3 arrays accepted
    numDimensions = ndims(rgb);
    if ~(numDimensions==2 || numDimensions==3) || size(rgb,numDimensions)~=3
        error(message('MATLAB:LightnessConverter:InvalidNumericShape'))
    end
    if numDimensions==3
        % Numeric data must be mx3 for lightness conversion.
        rgb = reshape(rgb,[],3);
    end
end
rgb = validatecolor(rgb,'multiple'); % Remaining validation
end

function colorValues = preserveSizeAndClass(colorValues, inputdata)
% Size and class are preserved for hex and nsizeumeric inputs. Named colors
% ('red','k') and mixed arrays are returned as an mx3 double matrix.
% Converting to an integer class or hex code will result in additional
% rounding of the double rgb values.
% +--------------+--------------+-------+--------------------+-------------+-----------------+
% |                                                          |          OUTPUTS              |
% |    Input     |    type      | Size  |      Example       |  SameClass  |    SameSize     |
% +--------------+--------------+-------+--------------------+-------------+-----------------+
% | 6 digit hex  | text         | any   | #68DC87            | yes         | yes             |
% | 3 digit hex  | text         | any   | #888               | yes         | yes (6-dig hex) |
% | Color name   | text         | any   | "red"|'k'          | no (double) | no  (mx3)       |
% | Mix (above)  | text         | any   | {'#F08','k','red'} | no (double) | no  (mx3)       |
% | RGB triplets | numeric      | mx3   | rand(4,3)          | yes         | yes             |
% | Truecolor    | numeric      | mxnx3 | rand(4,5,3)        | yes         | yes             |
% +--------------+--------------+-------+--------------------+-------------+-----------------+
% |                text: string array | character array | cell array of character vectors    |
% |                numeric: any numeric data type                                            |
% +--------------+--------------+-------+--------------------+-------------+-----------------+

if inputdata.ishex
    colorValues = rgb2hex(colorValues);
    if strcmpi(inputdata.class,'cell')
        colorValues = cellstr(colorValues);
    end
elseif inputdata.isnumeric
    % Convert double RGB values [0,1] back to input class and rescale to
    % integer class values to their integer max.
    if inputdata.isinteger
        imax = double(intmax(inputdata.class));
        imin = double(intmin(inputdata.class));
        colorValues = (imax-imin)*colorValues+imin;
    end
    colorValues = cast(colorValues, inputdata.class);
end
% Return shape to original size
if inputdata.ishex || inputdata.isnumeric
    if strcmpi(inputdata.class,'char')
        charArraySize = inputdata.size;
        charArraySize(2) = 1;
        colorValues = char(reshape(colorValues, charArraySize));
    else
        colorValues = reshape(colorValues, inputdata.size);
    end
end
end
