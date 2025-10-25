function nds = loadobj(S)
%

%   Copyright 2021 The MathWorks, Inc.

    import matlab.io.datastore.internal.RangeDatastore
    import matlab.io.datastore.internal.NestedDatastore

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > NestedDatastore.ClassVersion
            error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
        end
    end

    % Reconstruct the object.
    % The OuterDatastore gets reset during construction, so pass a different datastore
    % for now.
    nds = NestedDatastore(RangeDatastore(), S.InnerDatastoreFcn, IncludeInfo=S.IncludeInfo);

    % Recover the iterator position.
    nds.OuterDatastore = S.OuterDatastore; % Needs to be manually set to avoid reset() during construction.
    nds.InnerDatastore = S.InnerDatastore;
end
