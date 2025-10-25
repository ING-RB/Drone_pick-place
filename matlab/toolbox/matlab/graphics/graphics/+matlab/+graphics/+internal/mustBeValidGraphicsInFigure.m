function mustBeValidGraphicsInFigure(obj)
% mustBeValidGraphicsInFigure Validate that obj is an array of valid graphics
% objects & error if not. Used by FONTSIZE and FONTNAME. 
% This file is for internal use only and may change in a future release of
% MATLAB.

%   Copyright 2021 The MathWorks, Inc.

if ~all(isgraphics(obj))
    msg = message('MATLAB:graphics:fontfunctions:InvalidGfx');
    throwAsCaller(MException(msg));
end

figParent = ancestor(obj,'figure');
if isempty(figParent) || (iscell(figParent) && any(cellfun(@isempty,figParent)))
    msg = message('MATLAB:graphics:fontfunctions:NotInFigure');
    throwAsCaller(MException(msg));
end

end