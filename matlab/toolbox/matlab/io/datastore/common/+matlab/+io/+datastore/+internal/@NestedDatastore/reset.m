function reset(nds)
%RESET   Reset NestedDatastore to the start of the data.

%   Copyright 2021 The MathWorks, Inc.

    % Reset the outer datastore and set the inner datastore back to its default value.

    nds.OuterDatastore.reset();

    nds.InnerDatastore = matlab.io.datastore.internal.RangeDatastore();
end
