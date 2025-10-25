function tf = isvector(tv)
%ISVECTOR True if input is a vector.
%   TF = ISVECTOR(TV)
%
%   See also: ISVECTOR.

% Copyright 2016-2019 The MathWorks, Inc.

if tv.Adaptor.isKnownVector
    tf = tall.createGathered(true, getExecutor(tv));
elseif tv.Adaptor.isKnownNotVector
    tf = tall.createGathered(false, getExecutor(tv));
else
    % Need to defer calculation
    tf = isrow(tv) | iscolumn(tv);
    tf.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
end