function tf = isscalar(tv)
%ISSCALAR True if input is a scalar.
%   TF = ISSCALAR(TV)
%
%   See also: ISSCALAR.

% Copyright 2016-2023 The MathWorks, Inc.

if tv.Adaptor.isKnownScalar
    tf = tall.createGathered(true, getExecutor(tv));
elseif tv.Adaptor.isKnownNotScalar
    tf = tall.createGathered(false, getExecutor(tv));
else
    % Need to defer calculation
    tf = ismatrix(tv) & (numel(tv)==1); %#ok<ISCL>
    tf.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
end
