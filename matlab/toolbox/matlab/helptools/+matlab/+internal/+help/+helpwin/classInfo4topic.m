function classInfo = classInfo4topic(topic, justChecking)
%

%   Copyright 2020-2023 The MathWorks, Inc.

    classInfo = [];

    nameResolver = matlab.lang.internal.introspective.resolveName(topic, JustChecking=justChecking);
        
    if ~nameResolver.isUnderqualified
        classInfo = nameResolver.classInfo;
    end
end
