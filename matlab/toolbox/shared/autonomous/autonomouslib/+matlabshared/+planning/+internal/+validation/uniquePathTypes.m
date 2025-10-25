function uniqueDisabledTypes = uniquePathTypes(disabledTypes, allTypes)
%uniquePathTypes computes the unique set of path types specified for
%disabling. This is used in validating the DisabledPathTypesInternal
%property of DubinsConnection and ReedsSheppConnection.

% Copyright 2018-2019 The MathWorks, Inc.

%#codegen

    coder.internal.prefer_const(disabledTypes, allTypes);

    if isempty(disabledTypes)
        uniqueDisabledTypes = {};
        return;
    end

    if ~isempty(coder.target)
        % Code generation does not support unique for cell arrays. Loop over
        % entries to find the set of unique paths.

        dt = repmat({blanks(strlength(allTypes{1}))}, [1 numel(disabledTypes)]);
        for n = 1 : numel(disabledTypes)
            dt{n} = validatestring(disabledTypes{n}, allTypes, ...
                                   '', 'DisabledPathTypes');
        end

        % Compute indices mapping which entries in allTypes are present in
        % disableTypes. Maintain a count of how many entries exist so that
        % we can pre-allocate the cell array. This needs to be done because
        % concatenation of cell arrays is not supported in code generation.
        id      = false(size(allTypes));
        count   = 0;
        for n = 1 : numel(allTypes)

            % Loop over the disabledTypes to see if this path exists
            for d = 1 : numel(dt)
                if strcmp(allTypes{n}, dt{d})
                    id(n) = true;
                    count = count + 1;
                    break;
                end
            end
        end

        % Create a cell array with as many elements as there are unique
        % entries in disabledTypes
        % Use coder.nullcopy to keep the memory uninitialized, since the
        % coder does not detect that all elements are assigned in the
        % for-loop below.
        if isrow(disabledTypes)
            uniqueDisabledTypes = coder.nullcopy(cell(1,count));
        else
            uniqueDisabledTypes = coder.nullcopy(cell(count,1));
        end

        count = 1;
        for n = 1 : numel(allTypes)
            if id(n)
                uniqueDisabledTypes{count} = allTypes{n};
                count = count + 1;
            end
        end
    else
        % Use unique in MATLAB

        for n = 1 : numel(disabledTypes)
            disabledTypes{n} = validatestring(disabledTypes{n}, allTypes, '', ...
                                              'DisabledPathTypes');
        end

        uniqueDisabledTypes = unique(disabledTypes);
    end

    coder.internal.errorIf(numel(uniqueDisabledTypes)==numel(allTypes), ...
                           'shared_autonomous:motionModel:InvalidNumberPathTypes');
end
