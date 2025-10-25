function p = isReallyCellstr(S)
%#codegen

%checks homogeneous arrays for char base type


%   Copyright 2019 The MathWorks, Inc.

narginchk(1,1);
if iscell(S) && ~coder.target('MATLAB')
        ss = S;
        if coder.internal.isConst(isempty(ss)) && isempty(ss)
            p = true;
            return
        elseif coder.internal.tryMakeHomogeneousCell(ss)
            p = ischar(coder.internal.homogeneousCellBase(ss));
            return
        end
end
p = iscellstr(S); %#ok<ISCLSTR>

%--------------------------------------------------------------------------
end
