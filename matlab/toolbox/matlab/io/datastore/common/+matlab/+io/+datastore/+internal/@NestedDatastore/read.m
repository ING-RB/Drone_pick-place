function [data, info] = read(nds)
%READ   Return the next block of data from the NestedDatastore.
%
%   DATA = READ(NDS) reads the next block of data from the NestedDatastore.
%       It will start by reading through the outer datastore, and pass the
%       read data to the inner datastore.
%       The inner datastore will iterate through the data read by the outer datastore.
%       DATA here will always be the result from the inner datastore's read.
%
%   [DATA, INFO] = READ(NDS) also returns a struct containing additional information
%       about DATA.
%
%   See also: matlab.io.datastore.internal.NestedDatastore

%   Copyright 2021 The MathWorks, Inc.

    if ~nds.hasdata()
        msgid = "MATLAB:io:datastore:common:read:NoMoreData";
        error(message(msgid));
    end

    % If the InnerDatastore is empty, read from the OuterDatastore and construct a new InnerDatastore.
    if ~nds.InnerDatastore.hasdata()

        [outerData, outerInfo] = nds.OuterDatastore.read();

        if nds.IncludeInfo
            nds.InnerDatastore = nds.InnerDatastoreFcn(outerData, outerInfo);
        else
            nds.InnerDatastore = nds.InnerDatastoreFcn(outerData);
        end

        % At this point, if the InnerDatastore still returns hasdata-false, then we're
        % in a bit of a tricky state.
        % We need to return something from this function. If the InnerDatastore respects
        % the datastore contract, then readall() on an empty InnerDatastore will
        % return something vertically concatenable with the rest of the
        % InnerDatastores.
        % So return the readall() result for the InnerDatastore in this case.
        if ~nds.InnerDatastore.hasdata()
            data = nds.InnerDatastore.readall();

            % Similar problem for the info struct. What do we return here?
            % Just returning the outerInfo in this case for convenience.
            % TODO: is this really the most convenient thing to do?
            info = outerInfo;
            return;
        end
    end

    [data, info] = nds.InnerDatastore.read();
end
