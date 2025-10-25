function callbackPropertyNames = getCallbackPropertyNames(userComponent)
    %GETCALLBACKPROPERTYNAMES Returns the public callback property names that 
    % can be used in App Designer
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    metaClass =  metaclass(userComponent);
    
    callbackPropertyNames = appdesigner.internal.usercomponent.extractCallbackPropertyNamesFromMetaClass(metaClass);
end
