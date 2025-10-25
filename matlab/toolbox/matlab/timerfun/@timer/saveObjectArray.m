function B = saveObjectArray(obj)
%
%

%    Copyright 2001-2018 The MathWorks, Inc.

if isempty(obj)
    B = [];
else
    valid = isvalid(obj);
    B.size = size(obj);
    if any(valid(:))
        B.version = 3;  % Version to be used in 9a and forward. Version will be
                        % incremented only if loadobj is no longer able to read the new format.
        propNames = getSettableValues(obj);

        % Timers are Handles, but if you reconstruct two handles that are
        % to the same timer using loadObj, you still need to know which
        % elements pointed to the same object. Otherwise, on load, you'd
        % see two timers with the same Name and properties, but unique
        % objects.
        [obj,~,B.UniqueIndex] = unique(obj(:),'stable');
        B.valid = isvalid(obj); % invalid timers are not saved, but stored as a logical mask
        for i = 1:length(propNames)
            B.(propNames{i}) = get(obj(B.valid), propNames{i});
        end
    else
        % This is basically compressed invalid timer array.
        B.UniqueIndex = ones(B.size);
        B.valid = false;
    end
end
