function output = sharedTimerfind(timerObject, varargin)
%

%   Copyright 2015-2020 The MathWorks, Inc.

    [varargin{:}] = convertStringsToChars(varargin{:});

    if isa(timerObject, 'timer')
        % Check to see if the given object is all invalid
        if all(~isvalid(timerObject))
            output = []; % Return empty if all input timer handles are invalid
            return;
        end

        if all(isvalid(timerObject)) && isempty(varargin)
            % supporting case:
            % t1 =timer; t2 = timer;
            % timerfind([t1 t2]);
            % NOTE : this is undocumented, but previously this has worked and
            % we have test case for this; however, there should not be use case
            % for this, customer should resort to isvalid functionality directly.
            % This should be strongly discouraged and should be
            % considered for future incompatibility.
            % timerfind([t1 t2], Name, val) is still a valid case however,
            output = timerObject;
            return;
        end

        if any(~isvalid(timerObject)) && isempty(varargin)
            % supporting case:
            % t1 =timer; t2 = timer; delete(t1)
            % timerfind([t1 t2]);
            % NOTE : this is undocumented, but previously this has worked and
            % we have test case for this; however, there should not be use case
            % for this, customer should resort to isvalid functionality directly.
            % This should be strongly discouraged and should be
            % considered for future incompatibility.
            % timerfind([t1 t2], Name, val) is still a valid case however,
            output = [];
            return;
        end


        % the input should either be name-val-pair or a struct containing valid fields.
        if (isa(varargin{1}, 'struct'))
            if (numel(varargin{:}) ~= 1)
                error(message('MATLAB:timer:onlyOneStructInput'));
            end
        end
        if isa(varargin{1}, 'struct')
            findparam = struct2params(varargin{1});
        else
            findparam = varargin(1:end);
        end
        if mod(numel(findparam), 2)
            error(message('MATLAB:timer:incompletepvpair'));
        end

    else
        error(message('MATLAB:timer:invalid'));
    end

    % todo should become dead-code, leave here for now, until we have full qualification.
    % output = searchWithJavaTimers(timerObject, findparam);
    output = searchTimers(timerObject, findparam);
end

function output = searchTimers(timerObject, findparam)

    flattenedNameVal = convertStringsToChars(findparam(:))';

    if ~isempty(flattenedNameVal)
        idxsIntoTimerObject = [];
        for i = 1:numel(timerObject)
            matchingTimerMObj = findobj(timerObject(i), flattenedNameVal);
            if ~isempty(matchingTimerMObj)
                idxsIntoTimerObject  = [idxsIntoTimerObject i]; %#ok<AGROW>
            end
        end
    else
        idxsIntoTimerObject = 1:numel(timerObject);
    end

    % if nothing found, return empty set, otherwise return the timer object.
    if (isempty(idxsIntoTimerObject))
        output = timer.empty(0,0);
    else
        output = timerObject(idxsIntoTimerObject);
    end
end


function out = struct2params(aStruct)
    out = [];
    theFields = fieldnames(aStruct);
    currIdx = 1;
    for i = 1: numel(theFields)
        out{currIdx} = theFields{i}; %#ok<AGROW>
        out{currIdx + 1} = aStruct.(theFields{i}); %#ok<AGROW>
        currIdx = currIdx + 2;
    end
end
