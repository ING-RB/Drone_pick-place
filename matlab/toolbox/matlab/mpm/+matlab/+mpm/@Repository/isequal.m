%

%   Copyright 2024 The MathWorks, Inc.
function ret = isequal(repo, otherRepo)
    if ~isequal(size(repo), size(otherRepo))
        ret = false;
        return;
    end

    if ~isa(repo, 'matlab.mpm.Repository') || ~isa(otherRepo, 'matlab.mpm.Repository')
        ret = false;
        return;
    end

    ret = all(eq(repo, otherRepo));
end
