function result = visitUnderlyingDatastores(ds, visitFcn, combineFcn)
%visitUnderlyingDatastores   applies a function handle to all underlying
%   datastores in the tree, and combines the results using combineFcn.
%
%   See also: matlab.io.datastore.TransformedDatastore.visitUnderlyingDatastores

%   Copyright 2022 The MathWorks, Inc.

    % Visit the current datastore.
    % Performs validation of the function handles too.
    result1 = ds.visitUnderlyingDatastores@matlab.io.Datastore(visitFcn, combineFcn);

    % Visit the UnderlyingDatastores and combine the results together.
    result2 = ds.OuterDatastore.visitUnderlyingDatastores(visitFcn, combineFcn);
    result = combineFcn(result1, result2);

    result3 = ds.InnerDatastore.visitUnderlyingDatastores(visitFcn, combineFcn);
    result = combineFcn(result, result3);
end