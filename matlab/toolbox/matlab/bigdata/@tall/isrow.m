function tf = isrow(tv)
%ISROW True if input is a row vector.
%   TF = ISROW(TV)
%
%   See also: ISROW.

% Copyright 2016-2019 The MathWorks, Inc.

if tv.Adaptor.isKnownRow
    tf = tall.createGathered(true, getExecutor(tv));
elseif tv.Adaptor.isKnownNotRow
    tf = tall.createGathered(false, getExecutor(tv));
else
    % Need to defer calculation
    tf = ismatrix(tv) & (size(tv,1)==1);
    tf.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
end