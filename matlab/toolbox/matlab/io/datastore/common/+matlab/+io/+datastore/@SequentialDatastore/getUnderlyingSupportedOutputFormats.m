function outFmts = getUnderlyingSupportedOutputFormats(ds)
%GETUNDERLYINGSUPPORTEDOUTPUTFORMATS   Returns SupportedOutputFormats
%   common to all underlying datastores.
%

%   Copyright 2022 The MathWorks, Inc.

outFmts = [];
for idx = 1:numel(ds.UnderlyingDatastores)
    try
        if isa(ds.UnderlyingDatastores{idx}, "matlab.io.datastore.CombinedDatastore") || ...
                isa(ds.UnderlyingDatastores{idx}, "matlab.io.datastore.SequentialDatastore") || ...
                isa(ds.UnderlyingDatastores{idx}, "matlab.io.datastore.TransformedDatastore")
            currentDSOutFmts = getUnderlyingSupportedOutputFormats(ds.UnderlyingDatastores{idx});
        else
            currentDSOutFmts = ds.UnderlyingDatastores{idx}.SupportedOutputFormats;
        end
    catch
        currentDSOutFmts = [];
    end

    if isempty(currentDSOutFmts)
        % At least one underlying datastore has no common
        % SupportedOutputFormats with other underlying datastores.
        outFmts = [];
        return;
    end

    if isempty(outFmts)
        % First underlying datastore, nothing to compare with to find the
        % common SupportedOutputFormats.
        outFmts = currentDSOutFmts;
    else
        % Find the SupportedOutputFormats from current underlying datastore
        % common to all previous underlying datastores.
        outFmts = intersect(outFmts, currentDSOutFmts, 'stable');
        if isempty(outFmts)
            % Current underlying datastore has no common
            % SupportedOutputFormats with previous underlying datastores.
            return;
        end
    end
end
end