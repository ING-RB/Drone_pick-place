function msg = addClassHyperlink(msg,className)
%ADDCLASSHYPERLINK Adds a doc hyperlink to a class name in a message.
%   MSG = ADDCLASSHYPERLINK(MSG,CLASSNAME) wraps the instance of CLASSNAME in MSG with a
%   hyperlink to the doc page for that class. No link is added if hotlinks are off, or if
%   MSG does not contain CLASSNAME.

%   Copyright 2016-2021 The MathWorks, Inc.

if matlab.internal.display.isHot
    classLink = "<a href=""matlab:doc('" + className + "')"">" + className + "</a>";
    msg = replace(msg,className,classLink);
end
