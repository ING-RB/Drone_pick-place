function [parent, hasParent, pvpairs] = getParent(firstArgParent, pvpairs, partialPropNameNumChars)
% This function is undocumented and may change in a future release.

%   Copyright 2021-2023 The MathWorks, Inc.

% [parent, hasParent, pvpairs] = GETPARENT(firstArgParent, pvpairs, partialPropNameNumChars)
%   examines name-value pairs and parsed first argument parent to determine
%   the user-specified parent if there is one.
%
%   Inputs:
%       firstArgParent: Parent (e.g. as returned by peelFirstArgParent). Either
%       empty double (which indicates no parent specified as a first input
%       argument), empty GraphicsPlaceholder (which indicates user explicitly
%       specified an empty parent), or a parent.
%
%       pvpairs: Name-value pairs (e.g. as returned by peelFirstArgParent),
%       specified as a cell-array.
%
%       partialPropNameNumChars: number of characters in 'Parent' to match
%       (e.g. partialPropNameNumChars==3 will match 'Par' but not 'Pa'.
%
%   Outputs:
%       parent: the identified parent to use, which is the last specified
%       parent name-value pair if there is one, otherwise firstArgParent.
%
%       hasParent: true if the user specified a parent (i.e. a name value
%       pair is present OR firstArgParent is not specified as an empty double)
%
%       pvpairs: name-value pairs with all "Parent" name-value pairs removed.
%
%   GETPARENT will throw an appropriate exception if the identified parent
%   is not a graphics object, is not scalar, or is a deleted graphics object.

arguments
    firstArgParent
    pvpairs cell
    partialPropNameNumChars (1,1) double = 6
end

partialPropNameNumChars = max(min(partialPropNameNumChars, 6), 1);

% Default to whatever was in firstArgParent, which could be empty
parent = firstArgParent;
hasParent = ~isequal(parent,[]);

% Only remove the "Parent" name/value pairs if the third output was
% requested.
removeParentArguments = (nargout >= 3);
parentArgumentFound = false;

for i = numel(pvpairs)-1:-2:1
    if strlength(pvpairs{i}) >= partialPropNameNumChars ...
            && startsWith('parent',pvpairs{i}, 'IgnoreCase', true)
        if ~parentArgumentFound
            hasParent = true;
            parent = pvpairs{i+1};
            parentArgumentFound = true;
        end

        if removeParentArguments
            pvpairs([i i+1]) = [];
        else
            break
        end
    end
end

% Convert empty double to empty GraphicsPlaceholder.
if isequal(parent, [])
    parent = gobjects(0);
end

% Validate parent if found and not an empty GraphicsPlaceholder
if hasParent && ~isequal(parent, gobjects(0))
    if ~isa(parent, 'matlab.graphics.Graphics') || ~isscalar(parent)
        throwAsCaller(MException(message('MATLAB:graphics:axescheck:NonScalarHandle')))
    elseif ~isvalid(parent)
        if isa(parent,'matlab.graphics.axis.AbstractAxes')
            throwAsCaller(MException(message('MATLAB:graphics:axescheck:DeletedAxes')))
        else
            throwAsCaller(MException(message('MATLAB:graphics:axescheck:DeletedObject')))
        end
    end
end

end
