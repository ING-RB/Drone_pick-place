function n = numobservations(ds)
%NUMOBSERVATIONS   the number of observations in this datastore
%
%   N = NUMOBSERVATIONS(DS) returns the number of observations in
%   the current datastore state.
%
%   All integer values between 1 and N are valid indices for the
%   SUBSET method.
%
%   DS must be a valid datastore that returns isSubsettable true.
%   N is a non-negative double scalar.
%
%   See also matlab.io.Datastore.isSubsettable,
%   matlab.io.datastore.mixin.Subsettable.subset

%   Copyright 2022 The MathWorks, Inc.

ds.verifySubsettable("numobservations");
% Handle the empty case first.
if isempty(ds.UnderlyingDatastores)
    n = 0;
else
    n = sum(cellfun(@numobservations, ds.UnderlyingDatastores));
end
end