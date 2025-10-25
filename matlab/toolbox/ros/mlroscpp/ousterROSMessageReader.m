classdef ousterROSMessageReader < matlab.mixin.SetGet & matlab.mixin.Copyable

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = 'private')

        % Ouster ROS Messages
        OusterMessages

        % Name of Ouster calibration JSON file
        CalibrationFile
        
        % Total number of point cloud frames
        NumberOfFrames
        
        % Total duration of the messages
        Duration
        
        % Time of first point cloud reading
        StartTime
        
        % Time of final point cloud reading
        EndTime

        % Start time of each point cloud frame
        Timestamps
    end

    properties (Dependent)

        % Time of current point cloud reading
        CurrentTime (1, 1) duration
    end

    properties (Hidden)

        % Partial frame processing
        SkipPartialFrames
        
        % Coordinate frame for point cloud data 
        CoordinateFrame
        
        % Name of device model
        DeviceModel
        
        % Mode of lidar sensor
        LidarMode
                
        % Firmware version of Ouster sensor
        FirmwareVersion
        
        % Lidar data packet format
        LidarUDPProfile

        % Return modes of the point cloud data
        ReturnMode
    end

    properties (Access = 'private', Transient)

        %OusterROSMessageReaderObj Internal object for reading ROS messages
        OusterROSMessageReaderObj
    end

    properties (Access = 'private', Hidden)

        %UserCurrentTimeFlag Flag to determine if CurrentTime property is
        % set by user
        UserCurrentTimeFlag;

        %CurrentTimeInternal Same as CurrentTime but used for internal
        % purpose
        CurrentTimeInternal;

        %Version Version Number used for backward compatibility
        Version = 2.0;
    end

    %======================================================================
    % Custom Getters/Setters
    %======================================================================
    methods

        %==================================================================
        % Get CurrentTime property value
        %==================================================================
        function value = get.CurrentTime(obj)
            value = obj.CurrentTimeInternal;
        end

        %==================================================================
        % Set CurrentTime property value
        %==================================================================
        function set.CurrentTime(obj, value)
        % Check for value finiteness and acceptable limits
            if (value < obj.StartTime || value > obj.EndTime)
                error(message('ros:mlros:ouster:invalidCurrentTime', ...
                              char(obj.StartTime), char(obj.EndTime)));
            end

            obj.UserCurrentTimeFlag = true;
            obj.CurrentTimeInternal = value;
        end
    end

    methods (Access = 'public')

        %==================================================================
        % Constructor
        %==================================================================
        function obj = ousterROSMessageReader(ousterMessages, calibrationFile, nvArgs)

            arguments
                ousterMessages
                calibrationFile {mustBeNonempty, mustBeTextScalar, ouster.internal.checkFile(calibrationFile, '.json', 'JSON')}
                nvArgs.SkipPartialFrames (1,1) {mustBeA(nvArgs.SkipPartialFrames, 'logical'), mustBeNonsparse} = true
                nvArgs.CoordinateFrame {mustBeNonempty, mustBeTextScalar, mustBeMember(nvArgs.CoordinateFrame,{'center','base'})} = 'center'
            end

            % Validate ousterMessages
            validateattributes(ousterMessages,{'cell','struct','ros.msggen.ouster_ros.PacketMsg'},{'nonempty'},'ousterROSMessageReader','ousterMessages');

            % Convert OusterMessages to cell array with all structs for
            % each cell
            if isa(ousterMessages, 'ros.msggen.ouster_ros.PacketMsg')
                obj.OusterMessages = arrayfun(@(x) {toStruct(x)}, ousterMessages);
            elseif isstruct(ousterMessages)
                obj.OusterMessages = arrayfun(@(x) {x}, ousterMessages);
            elseif isa(ousterMessages{1}, 'ros.msggen.ouster_ros.PacketMsg')
                obj.OusterMessages = cellfun(@(x) {toStruct(x)}, ousterMessages);
            else
                obj.OusterMessages = ousterMessages;
            end
    
            % Check that all elements in ousterMessages contains Buf field
            for idx = 1:length(obj.OusterMessages)
                if (~isfield(obj.OusterMessages{idx}, 'Buf'))
                    error(message('ros:mlros:ouster:invalidArgType',idx));
                end
                if (isempty(obj.OusterMessages{idx}.Buf))
                    error(message('ros:mlros:ouster:emptyROSMessage',idx));
                end
            end

            % Retrieve calibration file
            fid = fopen(calibrationFile, 'r');
            obj.CalibrationFile = fopen(fid);
            fclose(fid);

            obj.SkipPartialFrames = nvArgs.SkipPartialFrames;
            obj.CoordinateFrame = char(nvArgs.CoordinateFrame);

            % Retrieve calibration data
            [obj.DeviceModel, obj.LidarMode, calibData] = ouster.internal.retrieveCalibrationData(obj.CalibrationFile);

            obj.FirmwareVersion = char(calibData.FirmwareVersion);
            obj.LidarUDPProfile = char(calibData.lidarUDPProfile);
            switch obj.LidarUDPProfile
                case {'LEGACY', 'RNG19_RFL8_SIG16_NIR16', 'RNG15_RFL8_NIR8'}
                    obj.ReturnMode = {'strongest'};
                case 'RNG19_RFL8_SIG16_NIR16_DUAL'
                    obj.ReturnMode = {'strongest' 'secondStrongest'};
            end

            calibData.skipPartialFrames = obj.SkipPartialFrames;
            if(strcmp(obj.CoordinateFrame, 'center'))
                calibData.lidarToSensorTform = eye(4);
            end

            % Create the ROS message reader object and load the messages
            try
                obj.OusterROSMessageReaderObj = roscpp.ouster.internal.OusterROSMessageReader();
                timeStruct = load(obj.OusterROSMessageReaderObj, obj.OusterMessages, calibData);
            catch ex
                error(ex.identifier, ex.message)
            end

            % Fill class properties returned from mex call
            if(~isempty(timeStruct))
                obj.NumberOfFrames = timeStruct.NumberOfFrames;
                obj.StartTime      = seconds(timeStruct.StartTime);
                obj.EndTime        = seconds(timeStruct.EndTime);
                obj.Duration       = seconds(timeStruct.Duration);
                obj.Timestamps     = seconds(timeStruct.TimestampsVector);
            end

            obj.CurrentTimeInternal = obj.StartTime;
            obj.UserCurrentTimeFlag = false;
        end

        %==================================================================
        % Read point cloud frame from ousterROSMessageReader object
        %==================================================================
        function [ptCloud, pcAttributes] = readFrame(obj, frameId, nvArgs)

            arguments
                obj (1,1) ousterROSMessageReader
                frameId (1,1) {mustBeA(frameId, ["duration", "numeric"]), mustBeNonsparse, mustBeNonNan, mustBeFinite, ouster.internal.checkFrameInput(frameId, obj)} = obj.CurrentTimeInternal
                nvArgs.ReadMode {mustBeNonempty, mustBeText, ouster.internal.checkReadMode(nvArgs.ReadMode, obj)} = obj.ReturnMode
            end

            % Identify the store order and convert to zero-based indexing
            [~, storeOrder] = ismember(nvArgs.ReadMode, obj.ReturnMode);
            storeOrder = uint8(storeOrder - 1);

            % Check if user provided duration object or updated CurrentTime value
            if (mod(nargin, 2) == 0 && isduration(frameId)) || obj.UserCurrentTimeFlag && nargin == 1
                % Convert to double, and remove start time
                durationToSeekSeconds = double(seconds(frameId - obj.StartTime));

                % Call builtin function with duration in seconds.
                [xyziPoints, intensity, range, signalPhoton, ...
                    nearInfrared, currentTimestamp] = readPointCloud(...
                    obj.OusterROSMessageReaderObj, obj.OusterMessages, durationToSeekSeconds, storeOrder);

            elseif isnumeric(frameId)
                % Convert to int32 and zero-based indexing
                frameNumber = int32(frameId - 1);

                % Call builtin function with frame number
                [xyziPoints, intensity, range, signalPhoton, ...
                    nearInfrared, currentTimestamp] = readPointCloud(...
                    obj.OusterROSMessageReaderObj, obj.OusterMessages, frameNumber, storeOrder);
            else
                % If user does not provide CurrentTime, read next point cloud in sequence
                if hasFrame(obj)
                    [xyziPoints, intensity, range, signalPhoton, ...
                        nearInfrared, currentTimestamp] = readPointCloud(...
                        obj.OusterROSMessageReaderObj, obj.OusterMessages, int32(-1), storeOrder);
                else
                    error(message('ros:mlros:ouster:endOfMessage'));
                end
            end

            if isempty(xyziPoints)
                % Return an empty pointCloud
                ptCloud = pointCloud(zeros(0, 0, 3, 'like', xyziPoints));
                pcAttributes = struct(Range={}, SignalPhoton={}, NearInfrared = {});
                % Reset the reader
                obj.CurrentTimeInternal = obj.StartTime;
            else
                % Create pointCloud object
                numPtClouds = length(storeOrder);
                numCols = size(xyziPoints, 2)/numPtClouds;
                % Create pointCloud object from xyziPoints, with points
                % sorted according to the laser vertical angles
                ptCloud = pointCloud.empty(0, numPtClouds);
                pcAttributes = [];
                for i=1:numPtClouds
                    colIds = ((i - 1) * numCols + 1) : (i * numCols);
                    ptCloud(i) = pointCloud(xyziPoints(:, colIds, :), ...
                        'Intensity', intensity(:, colIds));
                    rangeData = range(:, colIds);
                    if ~isempty(signalPhoton)
                        signalData = signalPhoton(:,colIds);
                    else
                        signalData = uint16([]);
                    end
                    if storeOrder(i) == 0
                        nirData = nearInfrared;
                    else
                        nirData = uint16([]);
                    end
                    pcAttributes = [pcAttributes struct(Range=rangeData, ...
                        SignalPhoton=signalData, NearInfrared = nirData)];
                end

                % Update current time
                obj.CurrentTimeInternal = obj.StartTime + seconds(currentTimestamp);
            end

            obj.UserCurrentTimeFlag = false;
        end

        %==================================================================
        % Check if another point cloud is available to read
        %==================================================================
        function flag = hasFrame(obj)
        % Check if timestamp of last frame requested is less than the
        % EndTime of the messages. Timestamps in the Ouster packet are reported
        % in nanoseconds. If the difference between EndTime and
        % CurrentTimeInterval is less than 1 nanosecond (i.e. 1e-9),
        % consider them to be close enough to report reaching last frame,
        % i.e, end of the messages reached and next frame unavailable.

            flag = abs(seconds(obj.EndTime) - seconds(obj.CurrentTimeInternal)) >= 1e-9;
        end

        %==================================================================
        % Reset ousterROSMessageReader object to beginning of the messages
        %==================================================================
        function reset(obj)

            obj.CurrentTime = obj.StartTime;
        end
    end

    methods (Hidden)
        %==================================================================
        % Clear resources
        %==================================================================
        function delete(obj)
        % Call builtin and release resources
            close(obj.OusterROSMessageReaderObj);
            % Invalidate class properties
            obj.OusterMessages       = [];
            obj.CalibrationFile      = [];
            obj.SkipPartialFrames    = true;
            obj.CoordinateFrame      = [];
            obj.DeviceModel          = [];
            obj.LidarMode            = [];
            obj.ReturnMode           = [];
            obj.FirmwareVersion      = [];
            obj.LidarUDPProfile      = [];
            obj.NumberOfFrames       = [];
            obj.Duration             = [];
            obj.StartTime            = [];
            obj.EndTime              = [];
            obj.Timestamps           = [];
            obj.CurrentTimeInternal  = seconds(0);
        end
    end

    methods(Access = 'protected')
        %==================================================================
        % Copy object
        %==================================================================
        function copyObj = copyElement(obj)
            % Override copyElement method inherited from
            % matlab.mixin.Copyable class to provide custom behavior for
            % making a copy of the ousterROSMessageReader object

            copyObj = ousterROSMessageReader(obj.OusterMessages, obj.CalibrationFile, ...
                'SkipPartialFrames', obj.SkipPartialFrames, ...
                'CoordinateFrame', obj.CoordinateFrame);
            copyObj.CurrentTime         = obj.CurrentTime;
            copyObj.UserCurrentTimeFlag = obj.UserCurrentTimeFlag;
            copyObj.Version             = obj.Version;
        end
    end

    methods(Hidden)
        %==================================================================
        % Save object
        %==================================================================
        function s = saveobj(obj)
        % Save properties into struct
            s.OusterMessages      = obj.OusterMessages;
            s.CalibrationFile     = obj.CalibrationFile;
            s.SkipPartialFrames   = obj.SkipPartialFrames;
            s.CoordinateFrame     = obj.CoordinateFrame;
            s.Version             = obj.Version;
            s.CurrentTime         = obj.CurrentTime;
            s.UserCurrentTimeFlag = obj.UserCurrentTimeFlag;
        end
    end

    methods (Static, Hidden)
        %==================================================================
        % Load object
        %==================================================================
        function obj = loadobj(s)
        % Load Object
            obj = ousterROSMessageReader(s.OusterMessages, s.CalibrationFile, ...
                'SkipPartialFrames', s.SkipPartialFrames, ...
                'CoordinateFrame', s.CoordinateFrame);
            obj.CurrentTime         = s.CurrentTime;
            obj.UserCurrentTimeFlag = s.UserCurrentTimeFlag;
            obj.Version             = s.Version;
        end
    end
end