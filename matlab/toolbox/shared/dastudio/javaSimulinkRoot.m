function w = javaSimulinkRoot

    persistent theRoot;

    if isempty(theRoot)
        theRoot = slroot;
    end

    w = java(theRoot);
    

%   Copyright 2002-2004 The MathWorks, Inc.
