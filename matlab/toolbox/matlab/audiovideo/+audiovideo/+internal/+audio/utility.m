classdef (Hidden) utility
    % Utility Supporting functionality for audio operations.
    %
    %   This class implements internal functionality required for audio
    %   operation. These methods are not intended for external use.
    %   Methods contained here are applicable to MATLAB Online only.

    % Copyright 2020-2022 The MathWorks, Inc.

    properties (Constant)
        EnumerateDevices = audiovideo.internal.audio.enumerateAudioDevices();
    end

    methods (Static)
        function [s, aOutList, aOutID, aInList, aInID, err] = enumerateAudioDevicesOnBrowser
            persistent audioOutputDeviceList audioOutputDeviceID audioInputDeviceList audioInputDeviceID errorMsg success

            import audiovideo.internal.audio.utility
            if ~ utility.EnumerateDevices.Enumerate
                s = success;
                aOutList = audioOutputDeviceList;
                aOutID = audioOutputDeviceID;
                aInList = audioInputDeviceList;
                aInID = audioInputDeviceID;
                err = errorMsg;
                return
            end

            % otherwise enumerate the devices
            h = utility.EnumerateDevices;
            h.Enumerate = false;

            audioOutputDeviceList = {};
            audioOutputDeviceID = {};
            audioInputDeviceList = {};
            audioInputDeviceID = {};
            errorMsg = [];
            success = true;
            isDone = false;
            sub = "";
            % Timer object setup. Start a timer with a selected timeout of
            % 10 seconds. If we receive data before the timeout, timer
            % would stop otherwise after the timeout, an empty output will
            % be returned to the user.
            t = timer('Period',0.5,'ExecutionMode','fixedRate','StartFcn',@sendRequestToBrowser, ...
                'TimerFcn',@checkIfDone,'StopFcn', @cleanup);
            t.TasksToExecute = round(10/ t.Period); % Timeout ~ 10s

            start(t);
            wait(t);    % enumerateAudioOutputDevicesOnBrowser wont return until the timer has elapsed
            delete(t);

            % Initiates request to get list of available audioOutputDevices from client
            function sendRequestToBrowser(~, ~)
                % Subscribe to /audio/publishlist channel to receive data
                % and publish on /audio/list channel to let the client know
                % that we are ready to receive data
                sub = message.subscribe("/audio/publishlist", @(msg) parseOutput(msg));
                message.publish("/audio/list", 0);
            end

            % Check if the client has returned with a list of audio devices
            function checkIfDone(mTimer, ~)
                % If /audioOutput/publishlist returns, either with a list of
                % audio devices or an error message, this is done.
                if isDone
                    stop(mTimer)
                end
            end

            % Unsubscribes from channel upon timeout or AUDIODEVICELIST assignment
            function cleanup(~, ~)
                message.unsubscribe(sub);
            end

            % Callback function upon receiving message from client.
            % Assigns the list of audio devices to the audioOutputDeviceList output variable
            function parseOutput(msg)
                isDone = true;
                if ischar(msg) % If there was an error in enumeration
                    errorMsg = msg;
                    success = false;
                elseif ~isempty(msg) % Parse list of audio devices
                    audioOutputMsg = msg(arrayfun(@(x) isequal(x.audioDeviceKind, 'audiooutput'), msg));
                    audioOutputDeviceInfo = struct2table(audioOutputMsg);
                    audioOutputDeviceList = (cellstr(audioOutputDeviceInfo.audioDeviceName))';
                    audioOutputDeviceID = audioOutputDeviceInfo.audioDeviceID;

                    audioInputMsg = msg(arrayfun(@(x) isequal(x.audioDeviceKind, 'audioinput'), msg));
                    audioInputDeviceInfo = struct2table(audioInputMsg);
                    audioInputDeviceList = (cellstr(audioInputDeviceInfo.audioDeviceName))';
                    audioInputDeviceID = audioInputDeviceInfo.audioDeviceID;
                end
            end

            s = success;
            aOutList = audioOutputDeviceList;
            aOutID = audioOutputDeviceID;
            aInList = audioInputDeviceList;
            aInID = audioInputDeviceID;
            err = errorMsg;
        end

        function [s, aOutList, aOutID, err] = enumerateAudioOutputDevicesOnBrowser
            import audiovideo.internal.audio.utility
            [s, aOutList, aOutID, ~, ~, err] = utility.enumerateAudioDevicesOnBrowser();

        end

        function [s, aInList, aInID, err] = enumerateAudioInputDevicesOnBrowser
            import audiovideo.internal.audio.utility
            [s, ~, ~, aInList, aInID, err] = utility.enumerateAudioDevicesOnBrowser();
        end

        function resetAudioDevices
            % this function forces the enumeration of audio devices by
            % generating the list again.
            import audiovideo.internal.audio.utility

            h = utility.EnumerateDevices;
            h.Enumerate = true;

            utility.enumerateAudioDevicesOnBrowser();
        end

        function ID = getInternalDeviceIDFromID(audioKind, deviceID)
            % This function finds the device web audio ID from its
            % customer-visible ID.
            % audioKind is 0 or 1 representing output or input devices
            import audiovideo.internal.audio.utility
            if (deviceID == -1) % Default device
                ID = 'default';
                return
            end

            % Get the details of all audio devices
            [~,outputDeviceList, outputDeviceIDs, inputDeviceList, inputDeviceIDs,~] = ...
                audiovideo.internal.audio.utility.enumerateAudioDevicesOnBrowser();

            % Get total count of unique audio devices
            uniqueInputDeviceCount = sum(utility.getIsDeviceUnique(inputDeviceList));
            uniqueOutputDeviceCount = sum(utility.getIsDeviceUnique(outputDeviceList));

            if audioKind
                audioDevicesIDs = {inputDeviceIDs{find(utility.getIsDeviceUnique(inputDeviceList))}};
                deviceIDs = 0 : uniqueInputDeviceCount-1;
            else
                audioDevicesIDs = {outputDeviceIDs{find(utility.getIsDeviceUnique(outputDeviceList))}};
                deviceIDs = uniqueInputDeviceCount : (uniqueInputDeviceCount+uniqueOutputDeviceCount)-1;
            end
            % Since deviceID is 0 based, add 1 to it while searching in
            % the array of device IDs
            idxs = deviceIDs == deviceID;
            % find the first non zero element in idxs
            deviceActIndx = find(idxs, 1, 'first');
            if isempty(deviceActIndx)
                % The deviceID is invalid, return an invalid value for the
                % audio player/recorder to handle
                ID = 'invalid';
                return;
            end
            ID = audioDevicesIDs{deviceActIndx};
        end

        function isDeviceUnique = getIsDeviceUnique(deviceList)
            % The function returns an array of the same size as input with
            % element 0 indicating a duplicate value and 1 indicating a
            % valid device label.
            % We have to remove the duplicate entries from the list.
            % There is usually an entry for a 'default' device and
            % another one which might correspond to 'communication' device.
            % If there are duplicates, remove the one with longer name
            numDevices = length(deviceList);
            isDeviceUnique = ones(1, numDevices);
            for d1 = 1:numDevices-1
                for d2 = d1+1:numDevices
                    % If one string is contained in the other, remove the
                    % one with longer name
                    if contains(deviceList{d1}, deviceList{d2})
                        % d1 is longer, remove d1
                        isDeviceUnique(d1) = 0;
                    elseif contains(deviceList{d2}, deviceList{d1})
                        % d2 is longer, remove d2
                        isDeviceUnique(d2) = 0;
                    end
                end
            end
        end
    end
end