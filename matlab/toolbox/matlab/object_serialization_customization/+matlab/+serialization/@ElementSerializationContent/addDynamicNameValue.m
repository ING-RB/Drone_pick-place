function obj = addDynamicNameValue(obj,propName,propVal,attr)
%
% Add a dynamic name-value and specify dynamic property attributes 
% during serialization 
%

%   Copyright 2023 The MathWorks, Inc.
    
    arguments
        obj
        propName (1,:) char
        propVal 
        attr.Description char
        attr.DetailedDescription char
        attr.GetAccess (1,:) char {mustBeMember(attr.GetAccess,{'public','protected','private'})}
        attr.SetAccess (1,:) char {mustBeMember(attr.SetAccess,{'public','protected','private'})}
        attr.Hidden (1,1) logical
        attr.GetObservable (1,1) logical
        attr.SetObservable (1,1) logical
        attr.AbortSet (1,1) logical 
        attr.NonCopyable (1,1) logical
    end 

    addDynamicNameValueAttr(obj, propName, propVal, attr);
end
