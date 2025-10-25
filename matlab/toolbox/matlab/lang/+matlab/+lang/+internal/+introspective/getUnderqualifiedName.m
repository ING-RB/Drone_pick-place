function [qualifiedTopic, methodName] = getUnderqualifiedName(topic, whichDescriptor)
    methodDescriptor = regexp(whichDescriptor, '\<(?<className>\S*) method$', 'names');
    if isempty(methodDescriptor)
        methodName = '';
        qualifiedTopic = '';
    else
        methodName = regexp(topic, '\S+(?=(\.\w+)?$)', 'match', 'once');
        qualifiedTopic = append(methodDescriptor.className, '/', methodName);
    end
end

%   Copyright 2022-2024 The MathWorks, Inc.
