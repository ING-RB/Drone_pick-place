function updateFoldersProperty(ds)
%updateFoldersPropertyWithNewFiles   a helper method for updating the
%   folders property whenever new files are added on the datastore.
%
%   For the initial datastore writeall release, this will clear the
%   Folders property if there are any changes to the Files property.

%   Copyright 2019 The MathWorks, Inc.

    % Reset the Folders property and avoid recalculation.
    ds.Folders = cell.empty(0, 1);
    ds.RecalculateFolders = false;
end
