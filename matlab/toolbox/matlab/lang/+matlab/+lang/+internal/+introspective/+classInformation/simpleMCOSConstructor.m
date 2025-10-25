classdef simpleMCOSConstructor < matlab.lang.internal.introspective.classInformation.fileConstructor
    methods
        function ci = simpleMCOSConstructor(className, whichTopic, justChecking)
            noAtDir = isempty(regexp(whichTopic, append('[\\/]@', className, '$'), 'once'));
            ci@matlab.lang.internal.introspective.classInformation.fileConstructor('', className, fileparts(whichTopic), whichTopic, noAtDir, justChecking);
        end

        function b = isClass(~)
            b = true;
        end
        
        function b = isMCOSClassOrConstructor(~)
            b = true;
        end
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
