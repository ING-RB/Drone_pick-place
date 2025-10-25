function result = visitUnderlyingDatastores(ds, visitFcn, combineFcn)
%visitUnderlyingDatastores   Overload for SequentialDatastore.
%
%   See also: matlab.io.Datastore.visitUnderlyingDatastores

%   Copyright 2022 The MathWorks, Inc.

% Visit SequentialDatastore itself.
% Performs validation of the function handles too.
result = ds.visitUnderlyingDatastores@matlab.io.Datastore(visitFcn, combineFcn);

% Visit all the UnderlyingDatastores and combine the results together.
for index = 1:numel(ds.UnderlyingDatastores)
    underlyingDs = ds.UnderlyingDatastores{index};
    underlyingResult = underlyingDs.visitUnderlyingDatastores(visitFcn, combineFcn);

    result = combineFcn(result, underlyingResult);
end
end