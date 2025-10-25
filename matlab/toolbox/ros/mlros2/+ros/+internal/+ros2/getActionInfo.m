function msgInfo = getActionInfo(msg,actionType,defType,type)
%This function is for internal use only. It may be removed in the future.

%   Copyright 2022-2023 The MathWorks, Inc.

%getActionInfo returns the prefix name to which _action_client or
%_action_server can be attached and other valuable information.
if nargin < 4
    type = 'action';
end
validateattributes(msg,{'char','string'},{'nonempty'});
validateattributes(type,{'char','string'},{'nonempty'});
msg = convertStringsToChars(msg);
actionType = convertStringsToChars(actionType);

[msgInfo.pkgName, msgInfo.actionName] = fileparts(actionType);
[~, msgInfo.msgName] = fileparts(msg);
msgInfo.defType = defType;
msgInfo.baseName = [msgInfo.pkgName, '_', 'msg' '_', msgInfo.msgName];
msgInfo.baseActionName = [msgInfo.pkgName, '_', type '_', msgInfo.actionName];
msgInfo.msgCppClassName = [msgInfo.pkgName,'::action::',msgInfo.actionName,'::',defType];
msgInfo.msgBaseCppClassName = [msgInfo.pkgName,'::action::' msgInfo.actionName];
msgInfo.msgStructGenFileName = [lower(msgInfo.msgName(1)) msgInfo.msgName(2:end)];
msgInfo.msgStructGen = ['ros.internal.ros2.messages.' msgInfo.pkgName '.' msgInfo.msgStructGenFileName];

msgInfo.libNameMap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
                                    { ...
                                      [msgInfo.pkgName,'.dll'], ...
                                      ['libmw', msgInfo.pkgName,'.dylib'],...
                                       ['libmw', msgInfo.pkgName,'.dylib'],...
                                      ['libmw', msgInfo.pkgName,'.so']...
                                    });

%Note: Path may not be always be available. This might be a custom message
%Note: getActionInfo can be called from augment while generating message
%files for services
%Hence: We cannot check for the presence of the files.
%RULE: getActionInfo should always give a msgInfo data
%Note: MCR separates toolbox MATLAB files from library files.
%      toolboxdir('ros') will find the root/mcr/toolbox/ros folder,
%      while the library files are in root/toolbox/ros/bin,
%      and interprocess files are in root/sys/ros2.
%      ctfroot points to the copied app folder, which will not have these
%RULE: Use matlabroot to find correct path to library files

msgInfo.path = fullfile(matlabroot,'toolbox','ros','bin',computer('arch'),...
                        msgInfo.libNameMap(computer('arch')));
msgInfo.cppFactoryClass = ['ros2_' msgInfo.pkgName '_'  msgInfo.actionName '_action'];

msgInfo.clientClassName = [msgInfo.baseActionName '_action_client'];
msgInfo.serverClassName = [msgInfo.baseActionName '_action_server'];
msgInfo.publisherClassName = [msgInfo.baseName '_publisher'];
msgInfo.subscriberClassName = [msgInfo.baseName '_subscriber'];

incl_message = ros.internal.utilities. ...
    convertCamelcaseToLowercaseUnderscore(msgInfo.actionName);
includeHeader = fullfile(msgInfo.pkgName,'action',[incl_message '.hpp']);
msgInfo.includeHeader = replace(includeHeader,'\','/'); %To be consistent across all platforms
msgInfo.custom = false;
msgInfo.srcPath   = [];
msgInfo.installDir = [];

%finally if there is a custom message, then overwrite
reg = ros.internal.CustomMessageRegistry.getInstance('ros2');
msgInfo = reg.updateMessageInfo(msgInfo);
