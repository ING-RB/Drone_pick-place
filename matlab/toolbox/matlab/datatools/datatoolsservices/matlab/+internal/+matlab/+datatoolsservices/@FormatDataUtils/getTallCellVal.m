% Special handling for tall variables, because the size of a tall variable may
% not be known, and there may be additional information available about the
% tall's underlying class.

% Copyright 2015-2023 The MathWorks, Inc.

function cellVal = getTallCellVal(currentVal)
    import internal.matlab.datatoolsservices.FormatDataUtils;

    tallInfo = matlab.bigdata.internal.util.getArrayInfo(currentVal);
    if isempty(tallInfo.Size) || isnan(tallInfo.Ndims)
        szz = '';
    else
        szz = internal.matlab.datatoolsservices.FormatDataUtils.getTallInfoSize(tallInfo);
    end

    cellVal = strtrim([szz ' ' FormatDataUtils.getClassString(currentVal)]);
    if ~isempty(tallInfo.Class)
        cellVal = [cellVal ' ' tallInfo.Class];
    end
    if ~tallInfo.Gathered
        cellVal = [cellVal ' (' ...
            getString(message('MATLAB:codetools:variableeditor:Unevaluated')) ')'];
    end
end
