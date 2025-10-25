function newColors = validateColorsArray(component, colorArray)
% Validates that COLORARRAY is a valid array of color
% specifications and returns an updated version NEWCOLORS that
% should be stored in a visual component.
%
% COLORARRAY can be any of the following:
%
% - Nx3 array of RGB values
% - 1xN or Nx1 cell array, where each element is an RGB triple or color
%   name. Color name can be a character vector or string.
% - an empty [] or {} array
%
% NEWCOLORS will always be an Nx3 array.

narginchk(2, 2)

% convert colorArray to char if string
colorArray = convertStringsToChars(colorArray);

% Check for {} and []
%
% Need to explicitly check for:
% - empty
% - numeric for [], or cell for {}
if(isempty(colorArray) && (isnumeric(colorArray) || iscell(colorArray)))
    newColors = [];
    return;
end

if(iscell(colorArray))
    % The input must be something like one of the following:
    %
    % {'red', 'green', 'blue'}
    % {'red', [.4 .2 .9], 'green'}
    validateattributes(colorArray, ...
        {'cell'}, ...
        {'vector'});

    % Validate each element and converts
    validationFcn = @(colorArray)matlab.ui.control.internal.model.PropertyHandling.validateColorSpec(component, colorArray);
    cellArrayOfRGBTriples = cellfun(validationFcn, colorArray, 'UniformOutput', false);

    % At this point, 'newColors' is a cell array of RGB values,
    % ex:
    %
    % {[1 0 0], [0 1 1]}
    %
    % Turn into Nx3 double matrix by stacking the RGB triples
    % on top of each other
    newColors = vertcat(cellArrayOfRGBTriples{:});
else
    % The input must be something like:
    %
    % [  0    1   0
    %    0.5  1   0
    %    0    1   0 ]

    % This validates the entire array.
    %
    % NaN in validate attributes means "don't worry about this
    % dimension."
    validateattributes(colorArray, ...
        {'numeric'}, ...
        {'size', [NaN,3], '>=', 0, '<=', 1});

    newColors = colorArray;
end
end