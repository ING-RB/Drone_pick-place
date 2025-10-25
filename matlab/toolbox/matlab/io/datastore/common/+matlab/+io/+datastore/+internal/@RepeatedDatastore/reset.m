function reset(rptds)
%RESET   Reset RepeatedDatastore to the start of the data.

%   Copyright 2021 The MathWorks, Inc.

    % Reset the outer datastore and set the inner datastore back to its default value.
    rptds.UnderlyingDatastore.reset();
    rptds.InnerDatastore = arrayDatastore([]);

    % Also reset the index datastore.
    rptds.UnderlyingDatastoreIndex.reset();

    % Also reset the cached data/info values.
    rptds.CurrentReadData = [];
    rptds.CurrentReadInfo = [];

    % Note that RepetitionIndices aren't cleared. This is intentional, as the populated
    % RepetitionIndices values are re-used on the next read through the datastore.
end
