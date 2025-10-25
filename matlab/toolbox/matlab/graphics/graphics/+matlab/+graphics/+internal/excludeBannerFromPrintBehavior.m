function excludeBannerFromPrintBehavior(fig, banner)
% This undocumented helper function is for internal use.

%   Copyright 2018 The MathWorks, Inc.

% Utility to hide interaction banner from export and print

bh = hggetbehavior(fig, 'Print');

set(bh, 'PrePrintCallback', @(~, ~) bannerPrePrintCallback(bh, banner)); 

% The behavior object should not be serialized to avoid serializing the 
% java InfoPanel (g1747588). Since the InfoPanel is not serialized
% otherwise, the behavior object is not needed on load
bh.Serialize = false;

function bannerPrePrintCallback(bh, banner)

% If the interaction banner is open, temporarily hide it and attach a 
% PostPrintCallback to restore it
if javaMethodEDT('isVisible',banner)
    set(bh,'PostPrintCallback', @(~, ~) bannerPostPrintCallback(banner));
    javaMethodEDT('setVisible',banner,false);
else
    set(bh,'PostPrintCallback', []);
end

function bannerPostPrintCallback(banner)

javaMethodEDT('setVisible',banner,true);    
drawnow
