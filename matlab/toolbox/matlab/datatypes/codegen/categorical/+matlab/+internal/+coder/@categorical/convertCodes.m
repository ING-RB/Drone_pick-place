function [bcodesout,bnamesout] = convertCodes(bcodes,bnames,anames,aprotect,bprotect,numCategoriesUpperBound) %#codegen
%CONVERTCODES Translate one categorical array's data to another's categories.

%   Copyright 2018-2020 The MathWorks, Inc.
if nargin < 6
    % assume no overlap in categories and set the upperbound to just the
    % sum of the number of categories in a and b
    numCategoriesUpperBound = length(anames)+length(bnames);
end
if nargin < 5
    aprotect = false;
    bprotect = false;
end

if ischar(bnames) % b was one string, not a categorical or cellstr, so never protected
    %ia = find(strcmp(bnames,anames));
    ia = matlab.internal.coder.datatypes.scanLabels(bnames, anames);

    % If ia is not constant, then we do not know if bnames is already a part of
    % anames and hence the actual size of bnamesout will be known at runtime. So
    % make it varsized with appropriate upperbound. If ia is known at
    % compile-time, then coder can determine its actual size.
    if ~coder.internal.isConst(ia) && coder.internal.isConst(numel(anames))
        coder.varsize('bnamesout', [numel(anames)+1 1], [true false]);
    end
    hasDifferentCategoryName = (ia == 0);
    if hasDifferentCategoryName
        coder.internal.errorIf(hasDifferentCategoryName && aprotect, ...
            'MATLAB:categorical:ProtectedForCombination');
        bnamesout = coder.nullcopy(cell(numel(anames)+1,1));
        for i = 1:numel(bnamesout)
            if i <= numel(anames)
                bnamesout{i} = anames{i};
            else
                bnamesout{i} = bnames;
            end
        end

        coder.internal.errorIf(length(bnamesout) > categorical.maxNumCategories, ...
            'MATLAB:categorical:MaxNumCategoriesExceeded',categorical.maxNumCategories);
        
        if coder.internal.isConst(numCategoriesUpperBound)
            if numCategoriesUpperBound <= 255-1 % intmax('uint8')-1
                bcodesout = uint8(length(bnamesout));
            elseif numCategoriesUpperBound <= 65535-1 % intmax('uint16')-1
                bcodesout = uint16(length(bnamesout));
            else
                % maximum size uint32. Codegen doesn't need uint64 because 
                % of the maximum array size limit 2^31-1
                bcodesout = uint32(length(bnamesout));
            end
        else
            % if we don't know number of categories, be safe and use the
            % largest integer type
            bcodesout = uint32(length(bnamesout));
        end
    else
        bnamesout = anames;
        if coder.internal.isConst(numCategoriesUpperBound)
            if numCategoriesUpperBound <= 255-1 % intmax('uint8')-1
                bcodesout = uint8(ia);
            elseif numCategoriesUpperBound <= 65535-1 % intmax('uint16')-1
                bcodesout = uint16(ia);
            else
                % maximum size uint32. Codegen doesn't need uint64 because 
                % of the maximum array size limit 2^31-1
                bcodesout = uint32(ia);
            end
        else
            % if we don't know number of categories, be safe and use the
            % largest integer type
            bcodesout = uint32(ia);
        end
    end

else % iscellstr(bnames)
    % Get a's codes for b's data.  Any elements of b that do not match a category of
    % a are assigned codes beyond a's range.
    [tf,ia] = matlab.internal.coder.datatypes.cellstr_ismember(bnames,anames);
    
    %b2a = categorical.createCodes([1,length(bnames)+1], numCategoriesUpperBound);
    if coder.internal.isConst(numCategoriesUpperBound)
        if numCategoriesUpperBound <= 255-1 % intmax('uint8')-1
            b2a = zeros(1,length(bnames)+1,'uint8');
        elseif numCategoriesUpperBound <= 65535-1 % intmax('uint16')-1
            b2a = zeros(1,length(bnames)+1,'uint16');
        else
            % maximum size uint32. Codegen doesn't need uint64 because 
            % of the maximum array size limit 2^31-1
            b2a = zeros(1,length(bnames)+1,'uint32');
        end
    else
        % if we don't know number of categories, be safe and use the
        % largest integer type
        b2a = zeros(1,length(bnames)+1,'uint32');
    end
    b2a(2:end) = ia;
    
    % a has more categories than b
    coder.internal.errorIf(nnz(ia) < length(anames) && bprotect, ...
        'MATLAB:categorical:ProtectedForCombination');
    
    % b has more categories than a
    ib = find(~reshape(tf,1,[]));

    % If tf is not constant, then we do not know if some names in bnames are
    % already a part of anames and hence the actual size of bnamesout will not be
    % known at runtime. So make it varsized with appropriate upperbound. If tf
    % is known at compile-time, then coder can determine its actual size.
    if ~coder.internal.isConst(tf) ...
        && coder.internal.isConst(numel(anames)) ...
        && coder.internal.isConst(numel(bnames))
        coder.varsize('bnamesout', [numel(anames)+numel(bnames) 1], [true false]);
    end
    hasDifferentCategoryName = ~all(tf,'all');
    if hasDifferentCategoryName
        % If a is protected and b has more categories, can't convert.
        coder.internal.errorIf(hasDifferentCategoryName && aprotect, ...
            'MATLAB:categorical:ProtectedForCombination');
        
        numCats = length(anames) + length(ib);
        coder.internal.errorIf(numCats > categorical.maxNumCategories, ...
            'MATLAB:categorical:MaxNumCategoriesExceeded',categorical.maxNumCategories);
        % Append new categories corresponding to b's extras
        b2a(ib+1) = length(anames) + (1:length(ib));

        if isempty(anames)
            if isempty(ib)
                bnamesout = cell(0,1);
            else
                bnamesout = coder.nullcopy(cell(numel(ib),1));
                for i = 1:numel(bnamesout)
                    bnamesout{i} = bnames{ib(i)};
                end
            end
        elseif isempty(bnames)
            bnamesout = reshape(anames,[],1);
        else
            bnamesout = coder.nullcopy(cell(numel(anames)+numel(ib),1));
            for ii = 1:numCats
                if ii <= numel(anames)
                  bnamesout{ii} = anames{ii};
                else
                  bnamesout{ii} = bnames{ib(ii-numel(anames))};
                end
            end
        end
    else
        if isempty(anames)
            bnamesout = cell(0,1);
        else
            bnamesout = anames;
        end
    end
    bcodesout = reshape(b2a(bcodes(:)+1),size(bcodes));
end
