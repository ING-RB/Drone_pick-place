function populateFoldersFromLocation(ds, location)
    %populateFoldersFromLocation is a convenience function for
    %   populating the Folders property from the location input to
    %   datastores.
    %
    %   The location input must be either:
    %     - A character vector listing a valid folder, file, or
    %       wildcard name.
    %     - A string array or cell array of character vectors 
    %       containing valid folder, file, or wildcard names.
    %     - A matlab.io.datastore.DsFileSet object.
    %
    %   The location input must be a list of valid files, folders, or
%   wildcards.
    %
%   See also: matlab.io.datastore.FoldersPropertyProvider

    %   Copyright 2019 The MathWorks, Inc.

    % Call into the optimized Folders population code, but with just one
    % input instead of three.
    ds.populateFoldersFromResolvedPaths(location);
end
