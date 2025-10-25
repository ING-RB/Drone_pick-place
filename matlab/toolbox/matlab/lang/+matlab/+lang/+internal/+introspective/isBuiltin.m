function b = isBuiltin(topic)
    if isDottedTopic(topic)
        b = contains(which(topic), 'built-in');
    else
        b = exist(topic, 'builtin');
    end
end

function b = isDottedTopic(topic)
    parts = split(string(topic), '.');
    b = all(arrayfun(@isValidIdentifier, parts));
end

function b = isValidIdentifier(name)
    b = isvarname(name) || iskeyword(name);
end

%   Copyright 2022 The MathWorks, Inc.
