% Compares two matlab.mpm.Repository objects for equality.
%
%   Two Repository objects are equal if they have the same repository Location

% Copyright 2024 The MathWorks, Inc.

function isEq = eq(repo, otherRepo)
    repoClass = "matlab.mpm.Repository";
    if ~isa(repo,repoClass)
        error(message("mpm:core:ComparisonNotDefined", class(repo), repoClass));
    end
    if ~isa(otherRepo,repoClass)
        error(message("mpm:core:ComparisonNotDefined", class(otherRepo), repoClass));
    end

    repoLocation = string(reshape([repo.Location], size(repo)));
    otherRepoLocation = string(reshape([otherRepo.Location], size(otherRepo)));

    try
        isEq = eq(repoLocation, otherRepoLocation);
    catch ex
        throw(ex)
    end
end
