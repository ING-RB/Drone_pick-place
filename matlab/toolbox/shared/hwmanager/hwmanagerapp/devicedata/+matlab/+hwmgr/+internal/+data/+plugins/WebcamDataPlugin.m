classdef WebcamDataPlugin < matlab.hwmgr.internal.data.plugins.PluginBase
    % Webcam data plugin for Hardware Manager apps

    % Copyright 2022-2023 The MathWorks, Inc.
    properties(Access = private, Constant)
        % Device icon id
        LiveTaskIcon = "acquireWebcamImage"
        WebcamBaseCode = "USBWEBCAM"
        ProductShortName = "webcam"
        LearnMoreDocTopicID = "acquirewebcamimage_intro"
    end

    methods

        function obj = WebcamDataPlugin()

            % Learn more about Acquire Webcam Image live task
            webcamTaskLearnMoreLink = matlab.hwmgr.internal.data.DataFactory.createDocLinkData(...
                obj.ProductShortName,obj.LearnMoreDocTopicID,...
                getString(message("hwmanagerapp:clientappdata:webcamtask:webcamTaskLearnMore")),...
                "https://www.mathworks.com/help/supportpkg/usbwebcams/ug/acquirewebcamimage.html");

            % Create Webcam live task data
            webcamLiveTaskData = matlab.hwmgr.internal.data.DataFactory.createLiveTaskData(...
                getString(message("hwmanagerapp:clientappdata:webcamtask:webcamTaskTitle")),...
                "matlab.hwmgr.internal.openAcquireWebcamImageLiveTaskExample",...
                "matlab.hwmgr.plugins.WebcamPlugin",...
                getString(message("hwmanagerapp:clientappdata:webcamtask:webcamDescription")),...
                obj.LiveTaskIcon, webcamTaskLearnMoreLink,...
                "SupportPackageBaseCodes", obj.WebcamBaseCode);
            obj.addLiveTaskData(webcamLiveTaskData);

            % Define Webcam device plugins acting as client enumerator
            if ismac
                if(strcmp(computer('arch'),'maca64'))
                    webcamDevPlugin = fullfile(matlabroot, "toolbox", "shared","testmeaslib", "hwutils", "shared_camera_util", "bin", "maca64", "libmwwebcamavfenumerator");
                else
                    webcamDevPlugin = fullfile(matlabroot, "toolbox", "shared","testmeaslib", "hwutils", "shared_camera_util", "bin", "maci64", "libmwwebcamavfenumerator");
                end
            elseif isunix
                webcamDevPlugin = fullfile(matlabroot, "toolbox", "shared","testmeaslib", "hwutils", "shared_camera_util", "bin", "glnxa64", "libmwwebcamgstenumerator");
            else % ispc
                webcamDevPlugin = fullfile(matlabroot, "toolbox", "shared", "testmeaslib", "hwutils", "shared_camera_util", "bin", "win64", "webcammfenumerator");
            end

            % Create AddOn Data for the MATLAB Support Package for USB Webcams
            webcamAddOnData = matlab.hwmgr.internal.data.DataFactory.createAddOnData( ...
                obj.WebcamBaseCode,...
                getString(message("hwmanagerapp:clientappdata:webcamtask:webcamSPKGFullName")),...
                "AsyncioDevicePlugin", webcamDevPlugin, "ClientEnumeratorAddOnSwitch", obj.WebcamBaseCode);
            obj.addAddOnData(webcamAddOnData);

            % Create the hardware keyword data
            keywordData = matlab.hwmgr.internal.data.DataFactory.createHardwareKeywordData( ...
                getString(message("hwmanagerapp:clientappdata:webcamtask:webcamKeyword")),...
                getString(message("hwmanagerapp:clientappdata:webcamtask:webcamDescription")),...
                getString(message("hwmanagerapp:clientappdata:webcamtask:webcamTooltip")),...
                "HardwareType",...
                "KeywordRelatedBaseCodes",obj.WebcamBaseCode);
            obj.addHardwareKeywordData(keywordData);
        end
    end
end
