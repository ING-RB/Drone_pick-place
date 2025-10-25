function trimmed = cellstr_strtrim(c) %#codegen
%CELLSTR_STRTRIM Remove leading and trailing whitespaces in a cellstr.
%   CELLSTR_STRTRIM implements strtrim for cellstr inputs in codegen.
%   Does not modify a char vector.

%   Copyright 2018-2021 The MathWorks, Inc.
coder.internal.prefer_const(c);
coder.extrinsic('matlab.internal.coder.datatypes.reshape0x0InCellstr');

% call strtrim as an extrinsic if input is constant
if coder.internal.isConst(c)
    trimmed = coder.const(matlab.internal.coder.datatypes.reshape0x0InCellstr(...
        feval('strtrim',coder.const(c))));
else
    if iscellstr(c) && ~( coder.internal.isConst(size(c)) && isempty(c) ) %#ok<ISCLSTR>
        % Use nullcopy to silent "not all elements assigned" error, as
        trimmed = coder.nullcopy(cell(size(c)));
        % need to unroll for long cellstrs (length > 1024)
        coder.unroll(~coder.target('MATLAB') && ~coder.internal.isHomogeneousCell(c));
        for i = 1:numel(c)
            trimmed{i} = strtrim(c{i});
        end
    else
        trimmed = c;
    end
end