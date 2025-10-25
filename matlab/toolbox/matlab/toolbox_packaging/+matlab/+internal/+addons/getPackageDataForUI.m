function [hasPackage, id, description, summary, displayName, version, organization, authorName, email, mlpaths, hasDependencies] = getPackageDataForUI(packageFolder)
    % If this packageFolder has a package definition in it, use that
    % data to populate the UI
    hasPackage = false;
    id = '';
    description =  '';
    summary =  '';
    displayName = '';
    version =  '';
    organization =  '';
    authorName =  '';
    email = '';
    mlpaths =  '';
    hasDependencies =  '';
    if matlab.internal.feature("mpm") && exist(fullfile(packageFolder,"resources","mpackage.json"), 'file')
        try
            pkg = matlab.mpm.Package(packageFolder);
                
            hasPackage = true;
            id = char(pkg.ID);
            description = char(pkg.Description);
            summary = char(pkg.Summary);
            displayName = char(pkg.DisplayName);
            version = char(string(pkg.Version));
            organization = char(pkg.Provider.Organization);
            authorName = char(pkg.Provider.Name);
            email = char(pkg.Provider.Email);
            folders = pkg.Folders;
            mlpaths = cellstr(fullfile(pkg.PackageRoot,[folders.Path])');
            hasDependencies = ~isempty(pkg.Dependencies);

        catch
            % mpackage.json likely was not valid, so no data to return
            hasPackage = false;
        end
        
    end

end