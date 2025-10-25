function sp = convertSamplePoints(sp,spMustBeDouble)
%convertSamplePoints Converts sample points for further processing.
% If spMustBeDouble is false, double, single, and uint64 sample points
% are not changed. int64 sample points are converted to uint64, all
% other types are converted to doubles.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2023 The MathWorks, Inc.

sp = full(sp);
if isdatetime(sp)
    sp = milliseconds(sp-mean(sp));
elseif isduration(sp)
    sp = milliseconds(sp);
elseif spMustBeDouble
    sp = double(sp);
elseif isfloat(sp) || isa(sp,'uint64')
    return
elseif isa(sp,'int64')
    sp = bitxor(typecast(sp, 'uint64'), 2^63);
    sp = sp - sp(1); % Sample points are always sorted in ascending order
else
    sp = double(sp);
end
end