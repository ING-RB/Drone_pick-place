function tf = anymissing(tv)
%ANYMISSING True if at least one element of a tall array is missing.
%   TF = ANYMISSING(TV)
%
%   See also: ANYMISSING, TALL

% Copyright 2021-2022 The MathWorks, Inc.

tf = aggregatefun(@anymissing, @any, tv);
tf.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
end
