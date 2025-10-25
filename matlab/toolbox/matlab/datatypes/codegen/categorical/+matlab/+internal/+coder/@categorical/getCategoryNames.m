function outCategoryNames = getCategoryNames(a,valueSet) %#codegen
%GETCATEGORYNAMES Determine categorical category names from a valueset.

%   Copyright 2018-2020 The MathWorks, Inc.

    iscellstrValueSet = iscellstr(valueSet);  %#ok<ISCLSTR>
    
    % Helper method to create category names based on valueSet
    if ~isempty(valueSet) % if valueSet is empty, no need to create names
        if isnumeric(valueSet)
            sz = numel(valueSet);
            categoryNames = coder.nullcopy(cell(sz,1)); 
            % declare varsize to force homogeneous
            if coder.internal.isConst(sz)
                coder.varsize('categoryNames', [], [false false]); 
            end

            if isfloat(valueSet) && any(valueSet ~= round(valueSet), 'all')
                % Create names using 5 digits. If that fails to create
                % unique names, the caller will have to provide names.
                if isreal(valueSet)
                    for k = 1:sz
                        % don't rely on sprintf for NaNs
                        if isnan(valueSet(k))
                            categoryNames{k} = 'NaN';
                        else
                            categoryNames{k} = sprintf('%0.5g', valueSet(k));
                        end
                    end
                else
                    for k = 1:sz
                        % don't rely on sprintf for NaNs
                        if isnan(real(valueSet(k)))
                            realpart = 'NaN';
                        else
                            realpart = sprintf('%0.5g', real(valueSet(k)));
                        end
                        if isnan(imag(valueSet(k)))
                            imagpart = 'NaN';
                        else
                            imagpart = sprintf('%0.5g', imag(valueSet(k)));
                        end
                        categoryNames{k} = [realpart '+' imagpart 'i'];
                    end
                end
            elseif isfloat(valueSet)
                % Create names that preserve up to 16 digits of flints
                if isreal(valueSet)
                    for k = 1:sz
                        categoryNames{k} = sprintf('%g', valueSet(k));
                    end
                else
                    for k = 1:sz
                        realpart = sprintf('%g', real(valueSet(k)));
                        imagpart = sprintf('%g', imag(valueSet(k)));
                        categoryNames{k} = [realpart '+' imagpart 'i'];
                    end
                end
            elseif isa(valueSet, 'int8') || isa(valueSet, 'int16') || ...
                    isa(valueSet, 'int32') || isa(valueSet, 'int64')% signed integer types
                % Create names that preserve all digits in integers
                for k = 1:sz
                    categoryNames{k} = sprintf('%d', valueSet(k));
                end
            else % unsigned integer types
                for k = 1:sz
                    categoryNames{k} = sprintf('%u', valueSet(k));
                end
            end

            unames = matlab.internal.coder.datatypes.cellstr_unique(categoryNames);            
            coder.internal.assert(length(unames) >= length(categoryNames), 'MATLAB:categorical:CantCreateCategoryNames');

            outCategoryNames = categoryNames;
        elseif islogical(valueSet)
            categoryNames = {'false'; 'true'};
            outCategoryNames = matlab.internal.coder.datatypes.cellstr_parenReference(categoryNames,valueSet(:)+1);
            % elseif ischar(valueSet)
            % Char valueSet is not possible
        elseif iscellstrValueSet
            % These may be specifying character values, or they may be
            % specifying categorical values via their names.

            % We will not attempt to create a name for the empty char
            % vectors or the undefined categorical label.  Names must
            % given explicitly. Double any because codegen doesn't
            % recognize valueSet as column vector, but it will be due to
            % constructor always vectorizing the input valueSet.
            coder.internal.assert(~any(any(strcmp(a.undefLabel,valueSet),1)), 'MATLAB:categorical:UndefinedLabelCategoryName', a.undefLabel);
            coder.internal.assert(~any(any(strcmp(a.missingLabel,valueSet),1)),'MATLAB:categorical:UndefinedLabelCategoryName', a.missingLabel);
            coder.internal.assert(~any(any(strcmp('',valueSet),1)), 'MATLAB:categorical:EmptyCategoryName');

            % Don't try to make names out of things that aren't character vectors.
            sz = numel(valueSet);
            mask = zeros(1,sz);
            for k = 1:numel(valueSet)
                mask(k) = size(valueSet{k},1);
            end

            coder.internal.assert(all(mask == 1),'MATLAB:categorical:CantCreateCategoryNames');

            outCategoryNames = cell(sz,1);
            for i = 1:sz
                outCategoryNames{i} = valueSet{i};
            end
        elseif isa(valueSet,'categorical')
            % We will not attempt to create a name for an undefined
            % categorical element.  Names must given explicitly.
            coder.internal.errorIf(any(isundefined(valueSet)),'MATLAB:categorical:UndefinedInValueset');

            bnames = reshape(cellstr(valueSet),numel(valueSet),1);
            outCategoryNames = bnames; % get a col, force the cellstr instead
        end
    else
        outCategoryNames = {}; % edge case when user provides empty for valueSet
    end    
end