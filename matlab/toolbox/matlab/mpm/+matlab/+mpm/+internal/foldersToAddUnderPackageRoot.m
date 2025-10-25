function choices = foldersToAddUnderPackageRoot(pkg)
% FOLDERSTOADDUNDERPACKAGEROOT Identifies valid folders to add under a package root folder.
%
%   CHOICES = FOLDERSTOADDUNDERPACKAGEROOT(PKG) returns a cell array of folder
%   names that are valid to be added under the specified package PKG's root. 
%   It filters out '.', '..', private folders, resource folders, and any
%   folders already included in the package.
%
%   This function is primarily intended for internal use by the
%   matlab.mpm.Package.addFolder method, facilitating tab completion by
%   providing a list of valid folder choices.

%   Copyright 2024 The MathWorks, Inc.

files = dir(pkg.PackageRoot);
folders = files([files.isdir] & ~strcmp({files.name}, '.') & ~strcmp({files.name}, '..') ...
    & ~startsWith({files.name}, '+') & ~startsWith({files.name}, '@') & ...
    ~strcmp({files.name}, 'private') & ~strcmp({files.name}, 'resources'));
folders = folders(~ismember({folders.name}, [pkg.Folders.Path]));
choices = {folders.name};
end
