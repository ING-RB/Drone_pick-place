function repos = mpmListRepositories()

    try
        repos = matlab.mpm.internal.listPackageRepositoriesHelper();
    catch exception
        throw(exception);
    end

    if nargout == 0
        if isempty(repos)
            disp(message("mpm:repository:NoRepositoriesConfigured").string())
        else
            matlab.mpm.internal.displayReposAsTable(repos);
        end
        clear repos
    end

end

%   Copyright 2023-2024 The MathWorks, Inc.
