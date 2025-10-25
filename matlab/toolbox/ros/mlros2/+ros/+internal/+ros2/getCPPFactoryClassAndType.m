function [cppFactoryClass , cppElementType] = getCPPFactoryClassAndType(msgType)
%This function is for internal use only. It may be removed in the future.

%getCPPFactoryClassAndType returns cpp frctory class and it is a equest or
%response or a message

%   Copyright 2021 The MathWorks, Inc.

    % Get list of services.
    introspec = ros.ros2.internal.Introspection();
    serviceList = introspec.getAllServiceTypes;
    actionList = introspec.getAllActionTypes;
    
    [pkgName, msgName] = fileparts(msgType);
    
    % Check if the message type is a request, response or a message
    if endsWith(msgName,'Request') && ...
            ismember(msgType(1:end-7),serviceList)
       cppFactoryClass = [pkgName '_' msgName(1:end-7) '_service'];
       cppElementType = 'Request';
    elseif endsWith(msgName,'Response') && ...
            ismember(msgType(1:end-8),serviceList)
        cppFactoryClass = [pkgName '_' msgName(1:end-8) '_service'];
        cppElementType = 'Response';
    elseif endsWith(msgName,'Goal') && ...
            ismember(msgType(1:end-4),actionList)
        cppFactoryClass = [pkgName '_' msgName(1:end-4) '_action'];
        cppElementType = 'Goal';
    elseif endsWith(msgName,'Feedback') && ...
            ismember(msgType(1:end-8),actionList)
        cppFactoryClass = [pkgName '_' msgName(1:end-length('Feedback')) '_action'];
        cppElementType = 'Feedback';
    elseif endsWith(msgName,'Result') && ...
            ismember(msgType(1:end-6),actionList)
        cppFactoryClass = [pkgName '_' msgName(1:end-6) '_action'];
       cppElementType = 'Result';
    else 
       cppFactoryClass = [pkgName '_' msgName '_message'];
       cppElementType = 'Message';
    end
    cppFactoryClass = ['ros2_' cppFactoryClass];
end