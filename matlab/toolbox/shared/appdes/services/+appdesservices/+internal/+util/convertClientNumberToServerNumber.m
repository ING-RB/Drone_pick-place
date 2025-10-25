function convertedValue = convertClientNumberToServerNumber(value)
% Helper function that consolodates the logic of converting
% things like:
%
% {'-Inf', 0}
% 'Inf'
% '123'
%
% to the proper double representation needed by MATLAB model
% objects.
%
% This is needed because property editor communicates with
% strings back to MATLAB to allow MATLAB to handle all
% precision / finessing
%
% Should be used by controller subclasses when interpreting
% edits coming from the client.

if(isjava(value))
    value = double(value);
    % g1335574: Transpose single dim arrays
    if(iscolumn(value))
        value = value';
    end
end

if(iscell(value))
    % Ex: 'Limits' {'Inf', 0}
    %
    % Recursively convert the two sub elements
    convertedValue = cellfun(@(val) appdesservices.internal.util.convertClientNumberToServerNumber(val), value, 'UniformOutput', false);
    isAllNumeric = cellfun(@isnumeric, convertedValue);
    if(isAllNumeric)
        convertedValue = cell2mat(convertedValue);
    end
    return;
end

if(ischar(value))
    % Ex: 'Inf'
    % Convert char version of limit -> number
    %
    % str2num is explicitly used because it works for both:
    %
    %   scalar numbers, ex: '1'
    %
    %   array numerics, ex: '0 Inf'
    %
    % TODO: consider if we want to use str2double.
    %
    %       Using str2num gives us eval-like behavior, and lets
    %       users type in things like "rand" and "1+2".  It
    %       seems like a nice feature but it definately wasn't
    %       explicitly intended when implemented.
    %
    [convertedValue, success] = str2num(value);     %#ok<ST2NM>

    if(~success)
        % the value wasn't converted sucessfully
        %
        % Either:
        % - the user typed in blank, in which case we will
        %   convert that to [] for them
        %
        % - they typed in something that wasn't a number that
        %   didn't evaluate, such as 'foo'
        %
        %   In this case, we will just return the string 'foo'.
        %
        %   When this is set on the component, it would error
        %   out for not being a number, and the error message
        %   comping from the component would be the same as if
        %   the user typed
        %
        %     >> obj.Property = 'foo'
        %
        % g1606351
        if(isempty(value))
            % user typed in ''
            % use empty
            convertedValue = [];
        else
            convertedValue = value;
        end

    end
    return
end

if(isnumeric(value))
    % Ex: 10
    % Do nothing
    convertedValue = value;
    return;
end
end
