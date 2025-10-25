function [list, metadata] = getcolormaplist()
% This undocumented function may be removed in a future release.

%   Copyright 2024 The MathWorks, Inc.

narginchk(0,0)
extPntSpec = matlab.internal.regfwk.ResourceSpecification;
extPntSpec.ResourceName = "mw.graphics.colormaps";
metadata = matlab.internal.regfwk.getResourceList(extPntSpec);
if isempty(metadata)
    error(message('MATLAB:colormap:MetadataInaccessible'))
else
    list = unique(string(vertcat(metadata.resourcesFileContents)),'stable');
end


