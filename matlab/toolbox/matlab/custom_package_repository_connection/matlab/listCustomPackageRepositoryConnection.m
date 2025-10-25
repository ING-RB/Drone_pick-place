function result = listCustomPackageRepositoryConnection()
%

%   Copyright 2024 The MathWorks, Inc.
    allRepos = mpmListRepositories();

    % convert matlab.mpm.Repository objects to struct array, each with Name and Location fields
    result = struct('Name', [allRepos.Name], 'Location', [allRepos.Location]);
end