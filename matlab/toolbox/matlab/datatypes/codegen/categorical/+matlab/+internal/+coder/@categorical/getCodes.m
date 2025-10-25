%#codegen
function codes = getCodes(a,inputData, valueSet)
    % Helper method used to turn inputData into codes based on
    % given valueSet
%   Copyright 2018 The MathWorks, Inc.

    iscellstrValueSet = iscellstr(valueSet);  %#ok<*ISCLSTR>
    iscellstrInput = iscellstr(inputData);

    % Assign category codes to each element of output
    tempcodes = zeros(size(inputData),'uint8'); % small as possible
    codes = a.castCodes(tempcodes,a.numCategoriesUpperBound); % only as big as needed

    if isnumeric(inputData)
        coder.internal.errorIf(~isnumeric(valueSet),'MATLAB:categorical:NumericTypeMismatchValueSet');

        [~,codes(:)] = ismember(inputData,valueSet);
        % NaN may have been given explicitly as a category, but there's
        % at most one by now
        nanpos = find(isnan(valueSet),1);
        if ~isempty(nanpos)
            for i = 1:numel(inputData)
                if isnan(inputData(i))
                    codes(i) = nanpos;
                end
            end
        end
    elseif islogical(inputData)

        if isnumeric(valueSet)
            valueSet = logical(valueSet);
        else
            coder.internal.assert(islogical(valueSet), 'MATLAB:categorical:TypeMismatchValueset');
        end
        trueCode = find(valueSet);
        falseCode = find(~valueSet);
        % Already checked that valueSet contains unique values, but
        % still need to make sure it has at most one non-zero.
        coder.internal.errorIf(length(trueCode) > 1, 'MATLAB:categorical:DuplicatedLogicalValueset');
        
        for i = 1:numel(inputData)
            if inputData(i) && ~isempty(trueCode)
                codes(i) = trueCode;
            elseif ~inputData(i) && ~isempty(falseCode)
                codes(i) = falseCode;
            end
        end
    elseif iscellstrInput
        % ismember requires that both inputs be of the same type
        coder.internal.assert(iscellstrValueSet, 'MATLAB:categorical:TypeMismatchValueset');
        
        % inputData and valueSet have already had leading/trailing spaces removed
        [~,codes(:)] = matlab.internal.coder.datatypes.cellstr_ismember(inputData,valueSet);

    elseif isa(inputData,'categorical')
        % This could be done in the generic case that follows, but this
        % should be faster.
        convert = zeros(1,length(inputData.categoryNames)+1,'like',codes);
        if isa(valueSet,class(inputData))
            undef = find(isundefined(valueSet)); % at most 1 by now
            if ~isempty(undef), convert(1) = undef(1); end
            valueSet = cellstr(valueSet); iscellstrValueSet = true;  %#ok<NASGU>
        else
            coder.internal.assert(iscellstrValueSet, 'MATLAB:categorical:TypeMismatchValueset');
        end
        
        [~,convert(2:end)] = matlab.internal.coder.datatypes.cellstr_ismember(inputData.categoryNames,valueSet);
        codes(:) = reshape(convert(inputData.codes+1), size(inputData.codes));
    else % anything else that has an eq method, except char (already weeded out)
        coder.internal.assert(isa(valueSet,class(inputData)), 'MATLAB:categorical:TypeMismatchValueset');
        coder.internal.assert(ismethod(inputData,'eq'), 'MATLAB:categorical:EQMethodFailedDataValueset');

        for i = 1:length(valueSet)
            codes(inputData==valueSet(i)) = i;
        end

    end
end
