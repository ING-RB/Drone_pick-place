% PlanarConfiguration - how the components are stored on disk.
%    This property should only be used when setting the
%    'PlanarConfiguration' tag.  Supported configurations include
%
%        Chunky   - The component values for each pixel are
%                   stored contiguously.  For example, in the case
%                   of RGB data, the first three pixels would be
%                   stored on file as RGBRGBRGB etc.
%        Separate - Each component is stored separately.  For
%                   example, in the case of RGB data, the red
%                   component would be stored separately on file
%                   from the green and blue components.
%
%    Almost all TIFF images have contiguous planar configurations.

% Copyright 2018 The MathWorks, Inc.
classdef PlanarConfiguration < uint32
    enumeration
        Chunky(1),
        Separate(2)
    end
end