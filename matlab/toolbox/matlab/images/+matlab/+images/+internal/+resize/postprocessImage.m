function [B,map] = postprocessImage(B_in, params)
% If input was indexed, convert output back to indexed.
% If input was binary, convert output back to binary.

% Copyright 2020 The MathWorks, Inc.

map = [];
if matlab.images.internal.resize.isInputIndexed(params)
    if strcmp(params.colormap_method, 'original')
        map = params.map;
        B = rgb2ind(B_in, map, params.dither_option);
    else
        [B,map] = rgb2ind(B_in, 256, params.dither_option);
    end
    
elseif islogical(params.A)
    B = B_in > 128;
    
elseif iscategorical(params.A)
    valueSet = 1:numel(params.inputCategories);
    B = categorical(B_in, valueSet, params.inputCategories);
    
else
    B = B_in;
end