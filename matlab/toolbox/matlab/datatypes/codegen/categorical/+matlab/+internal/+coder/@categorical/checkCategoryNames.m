function validNames = checkCategoryNames(rawnames,dupFlag)  %#codegen
%CHECKCATEGORYNAMES Validate a list of category names.

%   Copyright 2018-2020 The MathWorks, Inc.

coder.extrinsic('cellfun');

names = convertStringsToChars(rawnames);

% Allow 0x0 or 1x0 char, but not 0x1 or any other empty char
ischarname = matlab.internal.coder.datatypes.isCharString(names);
coder.internal.assert(ischarname || matlab.internal.coder.datatypes.isCharStrings(names), ...
    'MATLAB:categorical:CodegenInvalidNames', 'CATEGORYNAMES'); % since inputname does not work, use generic parameter name
if ischarname
    checkednames = {strtrim(names)};   
    coder.internal.errorIf(isempty(names),'MATLAB:categorical:EmptyName', 'CATEGORYNAMES');
else  % matlab.internal.coder.datatypes.isCharStrings(names)
    names = matlab.internal.coder.datatypes.cellstr_strtrim(names);
    if coder.internal.isConst(names)
        coder.internal.errorIf(any(coder.const(cellfun('isempty', names))),...
            'MATLAB:categorical:EmptyName', 'CATEGORYNAMES'); 
        checkednames = reshape(names,[],1);  
    else
        % forces cellstr to a column and make it homogeneous
        checkednames = cell(numel(names),1);
        if coder.internal.isConst(size(checkednames))
            coder.varsize('checkednames',[],[0 0]);
        end

        coder.unroll(coder.internal.isConst(size(names)));
        for i = 1:numel(checkednames)
            coder.internal.errorIf(isempty(names{i}),'MATLAB:categorical:EmptyName', 'CATEGORYNAMES');
            checkednames{i} = names{i};
        end
    end
end

coder.internal.assert(~any(strcmp(categorical.undefLabel,checkednames)),'MATLAB:categorical:UndefinedLabel', 'CATEGORYNAMES', categorical.undefLabel);
%coder.internal.assert(~any(strcmp(categorical.missingLabel,checkednames)),'MATLAB:categorical:UndefinedLabel', 'CATEGORYNAMES', categorical.missingLabel);


if dupFlag > 0 && length(checkednames) > 1
    if coder.internal.isConst(checkednames)
        [sortedCategories,ord] = coder.const(@feval,'sort', checkednames);
        if coder.internal.isConst(size(sortedCategories))
            coder.varsize('sortedCategories',[],[0 0]);
        end
    else
        [sortedCategories,ord] = matlab.internal.coder.datatypes.cellstr_sort(checkednames);
    end
    d = true(length(sortedCategories),1);
    for i = 2:length(sortedCategories)
        d(i) = ~strcmp(sortedCategories{i},sortedCategories{i-1});
    end
    containsDups = ~all(d);
    coder.internal.errorIf(containsDups && dupFlag == 2, ...
        'MATLAB:categorical:DuplicateNames', 'CATEGORYNAMES');
    if containsDups && dupFlag == 1
        % remove duplicate names
        validNames = matlab.internal.coder.datatypes.cellstr_parenReference(checkednames,sort(ord(d)));
    else
        validNames = checkednames;
    end
else
    validNames = checkednames;
end
