function [fullFile, toDelete] = resolvePath(base, src)
%resolvePath Resolve absolute paths, relative paths, and URLs.
%   [fullFile,toDelete] = resolvePath(base,src)

% Matthew J. Simoneau
% Copyright 1984-2021 The MathWorks, Inc.

if regexp(src,'^(https?|ftp):')
    fullFile = tempname;
    % websave returns the output filepath which can be different from the
    % input filepath. So, it has to be saved.
    fullFile = websave(fullFile, src);
    toDelete = fullFile;
else
    if matlab.io.internal.common.isAbsolutePath(src)
        fullFile = src;
    else
        fullFile = fullfile(fileparts(base), src);
    end
    toDelete = [];
end
