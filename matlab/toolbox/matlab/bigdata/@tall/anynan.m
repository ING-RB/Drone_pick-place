function tf = anynan(tv)
%ANYNAN True if at least one element of a tall array is Not-a-Number.
%   TF = ANYNAN(TV)
%
%   See also: ANYNAN, TALL

% Copyright 2021-2022 The MathWorks, Inc.

tf = aggregatefun(@anynan, @any, tv);
tf.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
end
