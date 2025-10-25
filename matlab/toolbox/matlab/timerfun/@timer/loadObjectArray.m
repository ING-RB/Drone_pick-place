function obj = loadObjectArray(B)
%

%    Copyright 2017-2021 The MathWorks, Inc.

if isstruct(B) && (isfield(B, 'version') && B.version == 3 || isfield(B,'valid') )
    if isfield(B,'valid')
        % Some of the timers might have been invalid.
        valid = B.valid;
    elseif iscell(B.Name) % Array case: saved before R2018b when invalid wasn't supported, has an array of timers
        valid = true(size(B.Name));
    else  % Scalar case: saved before R2018b when invalid wasn't supported. Scalars are saved without cell array.
        valid = true;
    end

    % invalid is be a logical mask
    obj = timer.empty;
    valsAreChar = (nnz(valid(:)) == 1);
    for index = 1:numel(valid)
        % this may seem like it could be vectorized, but it cannot.
        % Each timer needs to be created as a NEW timer because of the
        % handle semantics.
        if valid(index)
            % create a new timer, then put it into the output array.
            instance = timer;
            vals = getSettableValues(instance);
            for i = 1:length(vals)
                if valsAreChar
                    propVals = B.(vals{i});
                else
                    propVals = B.(vals{i}){index};
                end
                set(instance, vals{i}, propVals);
            end
            obj(index) = instance; %#ok<*AGROW>
        else
            % For invalid timers, create a new handle and then delete
            % it. This makes the element invalid on load.
            obj(index) = timer;
            delete(obj(index));
        end
    end

    % An array of duplicate timers saved will have a UniqueIndex to
    % indiacte which elements should be handles to the same timer.
    if isfield(B,'UniqueIndex')
        obj = obj(B.UniqueIndex);
    end
    if isfield(B,'size')
        obj = reshape(obj,B.size);
    end
elseif isempty(B)
    obj = timer.empty(size(B));
elseif (isstruct(B) && isfield(B,'jobject'))
    % possibly a struct with version 1 or 2
    % this is an all or nothing scenario. If we reach this case, we will
    % not try to do error-recovery from timer perspective, although mcos wil
    % do something and save an empty double matrix :(
    % we can get here in 2 different scenarios:
    % A. The original mat file had java streamed object intentionally
    % B. The original mat file had invalid timer
    % (created prior to R2018b, when valid was not a field, saved in the struct B)
    % in R2009a for example, valid timers will be saved and loaded as a
    % struct = B, invalid timers are loaded as a struct with jobject = B
    % we cannot differentiate among the 2 cases, so we are going to blindly
    % throw warning/error in both cases, and assume that they are invalid
    % timers.
    % For invalid timers, create a new handle and then delete
    % it. This makes the element invalid on load.

    obj = setinvalidTimerBasedOnLoadingSize(B);
    warning(message('MATLAB:timer:incompatibleTimerLoad'));
else
    % we give up case
    obj = B;
    warning(message('MATLAB:timer:unableToLoad'));
end
end