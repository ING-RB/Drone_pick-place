function shareApp(fullFileName, appType)
%SHAREAPP function will be used to open deploy tool GUI according to the
%appType passed in.
%
%Depending on the appType, this function will open Application Compiler for
%Desktop App or Web App. It will create a .prj file and then open the GUI
%for the compiler tool.

% Copyright 2020 The MathWorks, Inc.

    sharingStrategy = appdesigner.internal.share.AppSharingStrategyFactory.getStrategy(appType);
    sharingStrategy.share(fullFileName);
end
