function folders = getFolders(ds)

%   Copyright 2022 The MathWorks, Inc.

folders = cell.empty(numel(ds.UnderlyingDatastores), 0);
for idx = 1:numel(ds.UnderlyingDatastores)
    try
        folders{idx} = getFolders(ds.UnderlyingDatastores{idx});
    catch
    end
end

folders = vertcat(folders{:});

end