function tf = ismatrix(tv)
%ISMATRIX True if input is a matrix.
%   TF = ISMATRIX(TV)
%
%   See also: ISMATRIX.

% Copyright 2016-2019 The MathWorks, Inc.

if tv.Adaptor.isKnownMatrix
    tf = tall.createGathered(true, getExecutor(tv));
elseif tv.Adaptor.isKnownNotMatrix
    tf = tall.createGathered(false, getExecutor(tv));
else
    tf = (ndims(tv)==2); %#ok<ISMAT>
    tf.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
end