function w = javaDAClipboard

    persistent theClip;

    if isempty(theClip)
        theClip = DAStudio.Clipboard;
    end

    w = java(theClip);
    

%   Copyright 2002-2004 The MathWorks, Inc.
