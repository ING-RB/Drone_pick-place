function tf = isMcode(file)
% Is the given file a known type of analyzable M-code?

%   Copyright 2013-2020 The MathWorks, Inc.

    import matlab.depfun.internal.requirementsConstants
    
    tf = false;
    ext = extension(file);
    if ~isempty(ext)
        tf = ismember(ext, ...
                      requirementsConstants.analyzableMatlabFileExt_reverseOrder);
    end
end
