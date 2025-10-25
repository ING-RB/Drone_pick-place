function tf = iscolumn(tv)
%ISCOLUMN True if input is a column vector.
%   TF = ISCOLUMN(TV)
%
%   See also: ISCOLUMN.

% Copyright 2016-2019 The MathWorks, Inc.

if tv.Adaptor.isKnownColumn
    tf = tall.createGathered(true, getExecutor(tv));
elseif tv.Adaptor.isKnownNotColumn
    tf = tall.createGathered(false, getExecutor(tv));
else
    % Need to defer calculation
    tf = ismatrix(tv) & (size(tv,2)==1);
    tf.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
end