function waitfor(varargin)
%waitfor with a timeout
%   matlabshared.application.waitfor(obj, prop, value, 'Timeout', time)
%   wait until the object's prop changes to value or until the time is
%   reached. 'Timeout', time is optional. If no value is specified it will
%   wait until the value changes to any new value.

%   Copyright 2020 The MathWorks, Inc.
p = inputParser;
p.addRequired('Object');
p.addRequired('Property');
p.addOptional('Value', []);
p.addParameter('Timeout', []);

p.parse(varargin{:});
res = p.Results;
if ~isempty(res.Timeout)
    property = res.Property;
    object   = res.Object;
    if ~any(strcmp(p.UsingDefaults, 'Value'))
        % Check for a value. Loop till the property's value changes to the
        % specified value. Break when it does.
        value = res.Value;
        if object.(property) == value
            return;
        end
        t = tic;
        while toc(t) < res.Timeout && ~isequal(object.(property), value)
            drawnow;
        end
    else
        % Check for change in value. Break out of the while loop when the
        % value changes to a new one.
        oldValue = res.Object.(res.Property);
        t = tic;
        while toc(t) < res.Timeout && isequal(object.(property), oldValue)
            drawnow;
        end
    end
else
    waitfor(varargin{:});
end
end

% [EOF]
