function dataOut = iMakeUniform(dataIn, underlyingDatastore)
%IMAKEUNIFORM Force the uniform version of read of the underlying datastore.
%   We need to wrap the read in a cell if the underlying datastore is
%   non-uniform (E.G. imageDatastore / fileDatastore) and that datastore's
%   read method is not already combining multiple read units
%   together (E.G. imageDatastore with ReadSize > 1).

%   Copyright 2022 The MathWorks, Inc.

needToMakeUniform = matlab.io.datastore.internal.shim.isReadEncellified(...
    underlyingDatastore);
if needToMakeUniform
    dataOut = {dataIn};
else
    dataOut = dataIn;
end
end