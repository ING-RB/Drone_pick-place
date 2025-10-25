function repObj = fitDisplayRepresentationToWidth(obj, displayConfiguration, displayRep, width)
% fitDisplayRepresentationToWidth returns the representation object
% that fits in the available width. If displayRep does not fit in
% the available width, it defaults to dimensions and class name

% Copyright 2020-2021 The MathWorks, Inc.

import matlab.display.DimensionsAndClassNameRepresentation;
if any(displayRep.CharacterWidth > width)
    % If the width of the resulting display string is greater
    % than the available width, default to dimensions and class
    % name
    repObj = DimensionsAndClassNameRepresentation(obj, displayConfiguration);
else
    repObj = displayRep;
end
end