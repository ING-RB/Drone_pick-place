%This function is for internal use only. It may be removed in the future.
%
% Zeros out all of the fields on the struct in. - Cannot zero out fields
% that are set to enumerated types, since there is no possible way to cast
% a zero to an enumerated type. Fields set to enumerated types are not
% touched
%
% internal function, no error checking is performed

% Copyright 2021 The MathWorks, Inc.

%#codegen

function out = nullifyStruct(in)
out = in;
flds = fieldnames(in);
for m = 1:numel(flds)
    thisFld = flds{m};
    for n = 1:numel(in)
        thisVal = in(n).(thisFld);
        if isstruct(thisVal)
            nullVal =  matlabshared.tracking.internal.nullifyStruct(thisVal);
        else
            if isenum(thisVal)
                nullVal = thisVal; % Can't nullify enums
            else
                nullVal = zeros(size(thisVal),'like',thisVal);
            end
        end
        out(n).(thisFld) = nullVal;
    end
end
end
