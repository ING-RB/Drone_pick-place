function c = cellstr(s)
%

%   Copyright 1984-2023 The MathWorks, Inc.

if ischar(s)
    if isempty(s)
        c = {''};
    elseif ~ismatrix(s)
        error(message('MATLAB:cellstr:InputShape'))
    else
        numrows = size(s,1);
        c = cell(numrows,1);
        for i = 1:numrows
            c{i} = s(i,:);
        end
        c = deblank(c);
    end
elseif iscellstr(s)
    c = s;
elseif iscell(s)
    c = cell(size(s));
    for i=1:numel(s)
        if ischar(s{i}) || (isstring(s{i}) && isscalar(s{i}) && ~ismissing(s{i}))
            c{i} = char(s{i});
        else
            if (isstring(s{i}) && isscalar(s{i})) && ismissing(s{i})
                error(message('MATLAB:string:CannotConvertMissingElementToChar', i));
            else
                error(message('MATLAB:cellstr:MustContainText', i));
            end
        end
    end
else
    error(message('MATLAB:invalidConversion', 'cellstr', class(s)));
end
