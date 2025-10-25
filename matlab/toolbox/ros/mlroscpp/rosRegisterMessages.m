function rosRegisterMessages(genDir)
%rosRegisterMessages Register custom messages with MATLAB
%   rosRegisterMessages(GENDIR) registers the custom messages with
%   MATLAB. GENDIR is the path to the folder that contains
%   matlab_msg_gen_ros1.zip file. Use this function to register the custom
%   messages generated on another computer running on the same platform and
%   same MATLAB release version with MATLAB.
%
%
%   Example:
%
%      % Create a custom message package folder in a local directory.
%      genDir = fullfile(pwd,"rosCustomMessages");
%      packagePath = fullfile(genDir,"simple_msgs");
%      mkdir(packagePath)
% 
%      % Create a folder msg inside the custom message package folder.
%      mkdir(packagePath,"msg")
% 
%      % Create a .msg file inside the msg folder.
%      messageDefinition = {'int64 num'};
% 
%      fileID = fopen(fullfile(packagePath,'msg','Num.msg'),'w');
%      fprintf(fileID,'%s\n',messageDefinition{:});
%      fclose(fileID);
% 
%      % Create a folder srv inside the custom message package folder.
%      mkdir(packagePath,"srv")
% 
%      % Create a .srv file inside the srv folder.
%      serviceDefinition = {'int64 a'
%                           'int64 b'
%                           '---'
%                           'int64 sum'};
% 
%      fileID = fopen(fullfile(packagePath,'srv','AddTwoInts.srv'),'w');
%      fprintf(fileID,'%s\n',serviceDefinition{:});
%      fclose(fileID);
% 
%      % Create a folder action inside the custom message package folder.
%      mkdir(packagePath,"action")
% 
%      % Create an .action file inside the action folder.
%      actionDefinition = {'int64 goal'
%                          '---'
%                          'int64 result'
%                          '---'
%                          'int64 feedback'};
% 
%      fileID = fopen(fullfile(packagePath,'action','Test.action'),'w');
%      fprintf(fileID,'%s\n',actionDefinition{:});
%      fclose(fileID);
% 
%      % Generate custom messages from ROS definitions in .msg, .srv files and .action files.
%      rosgenmsg(genDir,CreateShareableFile=true)
%
%      % Copy the generated zip file to the target computer running MATLAB
%      %of the same release version and same operating system and register
%      %the generated custom messages using rosRegisterMessages function.
%      rosRegisterMessages(genDir)
%
%   See also rosgenmsg, rosmessage, rosmsg.

% Copyright 2022 The MathWorks, Inc.

if nargin < 1
    genDir = pwd;
end

genZipFile = fullfile(genDir,'matlab_msg_gen_ros1.zip');
if ~isfile(genZipFile)

    %If there is no zip file present in the input directory, we throw
    %an error saying to provide the correct input folder.
    error(message('ros:utilities:custommsg:NoZipFileExists','matlab_msg_gen_ros1.zip'))
else
    if isfolder(fullfile(genDir,'matlab_msg_gen_ros1'))

        %If there exists a folder named matlab_msg_gen_ros1 in the
        %provided input directory, we throw an error saying to copy the
        %zip file to any other input folder and execute the
        %registration.
        error(message('ros:utilities:custommsg:FolderExists','matlab_msg_gen_ros1'))
    else
        unzip(genZipFile, genDir);
    end
end

versionStorageMapPath = fullfile(genDir,'VersionInfo.mat');
load(versionStorageMapPath,'versionStorageMap');

%Sharing of custom messages is supported only to same platform. If user
%tries to copy a zip file of one platform to other, we throw an error
%message and give a link to user which will re-generate custom messages
%for him by clicking on it.
if ~isequal(versionStorageMap('Platform'),computer('arch'))
    error(message('ros:utilities:custommsg:PlatformNotSupported',computer('arch'),'rosgenmsg',genDir))
end

%Sharing of custom messages is supported only to same release. If user
%tries to copy a zip file of one release to other, we throw an error
%message and give a link to user which will re-generate custom messages
%for him by clicking on it.
if ~isequal(versionStorageMap('Release'),version('-release'))
    error(message('ros:utilities:custommsg:ReleaseNotSupported',version('-release'),versionStorageMap('Release'),'rosgenmsg','genDir'))
end

%Get the MessageTypes, ServiceTypes and ActionTypes from the MAT file.
msgFullName = versionStorageMap('MessageList');
srvFullNameRequest = versionStorageMap('ServiceRequestList');
srvFullNameResponse = versionStorageMap('ServiceResponseList');
srvFullName = versionStorageMap('ServiceList');
actionFullName = versionStorageMap('ActionList');

% Update preferences with folder information
reg = ros.internal.custommsgs.updatePreferences(msgFullName,srvFullNameRequest,srvFullNameResponse,srvFullName,actionFullName,'ros',genDir); %#ok<NASGU>

%Give the final instructions to the user.
ros.internal.custommsgs.finalInstructions(genDir);
end