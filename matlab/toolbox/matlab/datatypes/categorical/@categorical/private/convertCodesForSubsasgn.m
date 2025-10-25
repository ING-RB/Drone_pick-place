function [bcodes,anames] = convertCodesForSubsasgn(bcodes,bnames,anames,aprotect)
% This is a version of convertCodes modified for the specifics of subsasgn.
% Assigning from b into a, so:
% * Need to return updated category names for a, not b, and a's list is grown
%   only by the (new) categories from b that are actually being assigned,
%   ignoring those that are not being assigned
% * Don't care if b is protected
% * If a is protected, only care if the values actually being assigned are not
%   categories in a. Unused categories in b not in a don't matter.

%   Copyright 2019 The MathWorks, Inc.

try
    
    if ischar(bnames)
        ia = find(strcmp(bnames,anames));
        if isempty(ia)
            if aprotect
                throwAsCaller(MException(message('MATLAB:categorical:ProtectedForCombination')));
            end
            anames = [anames; bnames];
            bcodes = length(anames);
        else
            bcodes = ia;
        end
        
        numCats = length(anames);
        if numCats > categorical.maxNumCategories
            throwAsCaller(MException(message('MATLAB:categorical:MaxNumCategoriesExceeded',categorical.maxNumCategories)));
        end
        % Leave bcodes as a scalar double, main subsasgn function assigns it into
        % an integer array, so no cast needed here.
        
    else % iscellstr(bnames)
        % Get a's codes for b's data.  Any elements of b that do not match a category of
        % a are assigned codes beyond a's range.
        [tf,ia] = ismember(bnames,anames);
        b2a = zeros(1,length(bnames)+1,categorical.defaultCodesClass);
        b2a = categorical.castCodes(b2a, length(anames)); % enough range to store ia, may upcast later
        b2a(2:end) = ia;
        
        % b has categories not present in a
        if ~all(tf)
            % Find b's categories that are actually being newly assigned into a.
            % Don't care about other categories in b but not in a.
            newlyAssigned(unique(bcodes(bcodes>0))) = true;
            newlyAssigned(tf) = false;
            
            % If a is protected we can't assign new categories.
            if any(newlyAssigned)
                if aprotect
                    throwAsCaller(MException(message('MATLAB:categorical:ProtectedForCombination')));
                end
                ib = find(newlyAssigned);
                numCats = length(anames) + length(ib);
                if numCats > categorical.maxNumCategories
                    throwAsCaller(MException(message('MATLAB:categorical:MaxNumCategoriesExceeded',categorical.maxNumCategories)));
                end
                % Append new categories corresponding to b's extras, possibly upcasting b2a
                b2a = categorical.castCodes(b2a, numCats);
                b2a(ib+1) = length(anames) + (1:length(ib));
                anames = [anames; bnames(ib)];
            end
        end
        bcodes = reshape(b2a(bcodes+1),size(bcodes));
    end
    
catch ME
    if aprotect && (ME.identifier == "MATLAB:categorical:ProtectedForCombination")
        names = setdiff(bnames,anames);
        throwAsCaller(MException(message('MATLAB:categorical:ProtectedForAssign',names{1})));
    else
        throwAsCaller(ME);
    end
end
