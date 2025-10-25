function recordtxt(h,TextType,Text)
%RECORDTXT  Records text into the @recorder object.

%   Author: P. Gahinet  
%   Copyright 1986-2004 The MathWorks, Inc.

switch lower(TextType)
case 'history'
    h.EventRecorder.add2hist(Text);
case 'commands'
    
end