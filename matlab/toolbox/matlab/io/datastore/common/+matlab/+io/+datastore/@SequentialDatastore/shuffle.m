function shufds = shuffle(ds)
%SHUFFLE    Return a shuffled version of this SequentialDatastore
%
%   NEWDS = SHUFFLE(DS) returns a randomly shuffled copy of DS.
%
%   A SequentialDatastore is only shuffleable when all
%   of its underlying datastores are shuffleable. The isShuffleable
%   method indicates whether a datastore is shuffleable or not.
%
%   See also isShuffleable, matlab.io.datastore.Shuffleable

%   Copyright 2022 The MathWorks, Inc.

ds.verifyShuffleable("shuffle");

rndIdxes = randperm(numel(ds.UnderlyingDatastores));
shufds = matlab.io.datastore.SequentialDatastore();

% Shuffle each underlying datastore and also shuffle the order of the
% UnderlyingDatastores list.
shufds.UnderlyingDatastores = cellfun(@(innerDs) innerDs.shuffle(), ...
    ds.UnderlyingDatastores(rndIdxes), ...
    UniformOutput=false);
end