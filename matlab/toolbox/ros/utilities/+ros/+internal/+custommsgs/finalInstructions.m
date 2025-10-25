function finalInstructions(genDir)
%This function is for internal use only. It may be removed in the future.

%FINALINSTRUCTIONS provides instructions to the user after completion of
%rosgenmsg.

%   Copyright 2022 The MathWorks, Inc.

% Final instructions to the user to be able to use message classes
disp(' ');
disp(message('ros:mlroscpp:rosgenmsg:ToUseCustomMessages').getString)
disp(' ');
disp(message('ros:mlroscpp:rosgenmsg:Step1AddPath').getString);
disp(' ')
msgClassFolder = fullfile(genDir, 'install', 'm');
disp(strcat('addpath(''', msgClassFolder, ''')'));
disp('savepath');
disp(' ');
disp(message('ros:mlroscpp:rosgenmsg:Step2ClearRehash').getString)
disp(' ');
disp('clear classes')
disp('rehash toolboxcache')
disp(' ');
disp(message('ros:mlroscpp:rosgenmsg:Step3Verify').getString);
disp(' ')
end