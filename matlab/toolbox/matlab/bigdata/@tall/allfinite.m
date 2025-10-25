function tf = allfinite(tv)
%ALLFINITE True if every element of a tall array is finite.
%   TF = ALLFINITE(TV)
%
%   See also: ALLFINITE, TALL

% Copyright 2021-2022 The MathWorks, Inc.

tv = tall.validateType(tv, mfilename, {'~table', '~timetable'}, 1);

tf = aggregatefun(@allfinite, @all, tv);
tf.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
end
