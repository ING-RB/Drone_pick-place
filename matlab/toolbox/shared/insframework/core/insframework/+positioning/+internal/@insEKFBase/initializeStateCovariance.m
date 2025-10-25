function initializeStateCovariance(filt)
%INITIALIZESTATECOVARIANCE Reset the state covariance matrix
%   This method is for internal use only. It may be removed in the future. 

%   Copyright 2021 The MathWorks, Inc.

%#codegen   

opts = filt.Options;
filt.StateCovariance = eye(filt.NumStates, opts.Datatype);
