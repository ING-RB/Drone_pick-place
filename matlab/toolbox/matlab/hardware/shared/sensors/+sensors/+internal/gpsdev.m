classdef (Hidden) gpsdev <  matlabshared.sensors.sensorInterface
    %GPSDEV creates a connection to GPS receiver
    %
    %  Syntax:
    %      gpsObj = gpsdev(hardwareObj) creates a connection to GPS receiver
    %      connected to serial port of the hardware board specified by 
    %      hardwareObj with default property values.
    %      gpsObj = gpsdev(hardwareObj,Name,Value) creates a connection to
    %      GPS receiver connected to serial port of the hardware board 
    %      specified by hardwareObj with property values specificied as
    %      additional Name-Value options.
    %
    %  GPSDEV properties:
    %
    %   SerialPort : The ID of the serial port available on the Arduino
    %   hardware specified as a number. Default value is 1.
    %
    %   Nontunable properties:
    %
    %   ReadMode        -  Choose whether to read the latest available 
    %                      readings or the values accumulated from the 
    %                      beginning.The property can have value
    %                      'latest'(default) or 'oldest'.
    %   SamplesPerRead   - Specify number of samples returned per execution
    %                      of read. A positive integer in the range [1 10].
    %                      Default value is 1.
    %   OutputFormat     - Specify the format of output data. The property
    %                      can have value 'timetable' (default) or 'matrix'. 
    %
    %   Tunable properties:
    %
    %   TimeFormat       - Specify the format of time displayed when the 
    %                      GPS data is read. The property can have value
    %                      'datetime' (default) or 'duration'.
    %
    %   Read only properties:
    %
    %   SamplesAvailable - Number of samples remaining in the buffer 
    %                    - waiting to be read.
    %   SamplesRead      - Number of samples read from the sensor.
    %   BaudRate         - The baudrate at which hardware object is
    %                      expecting data from GPS receiver.
    %
    %  GPSDEV methods:
    %
    %   read              - Returns one frame each of lla (latitude,
    %                       longitude, altitude), ground speed, course, 
    %                       DOPs (PDOP, HDOP, VDOP) and GPS receiver time
    %                       along with time stamps and overrun. The number
    %                       of samples in a frame depends on the 
    %                       'SamplesPerRead' value specified while creating 
    %                       the sensor object. The output format can be
    %                       'timetable' or 'matrix' depends on the
    %                       'OutputFormat' values specified while creating
    %                       the sensor object.
    %   flush             - Flushes all the data accumulated in the buffers
    %                       and resets 'SamplesAvailable' and 'SamplesRead'.
    %   writeBytes        - Writes raw commands to GPS module.
    %   info              - Returns GPS Update Rate, Number of Satellites 
    %                       in view the module can use and GPS lock 
    %                       information.
    %   stop/release      - Tells hardware to stop sending data and release
    %                       the system object.
    
    
    %   Copyright 2020-2021 The MathWorks, Inc.
    
    properties(Access = private)
        ConnectionObj;
        StoredData = [];
        StoredTimeStamp = [];
        RMCData= [];
        GGAData = [];
        GSAData = [];
        DataNames = ["LLA","GroundSpeed","Course","DOPs","GPSReceiverTime"];
        UpdateRate = [];
        GPSLocked = false;
        SatellitesInView = [];
        IsFlushBuffers = 0;
        ToleranceTime = 120; % Buffers will be flushed if the time between subsequent read exceeds 120s
        PrevTimeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
        TimerVal = [];
        LastReadTime = 0;
    end
    
    properties (Access = protected)
        startTime;
        MaxSamplesPerRead = 10;
    end
    
    properties (Hidden,SetAccess = private)
        PrevData =[]; % This is to store the previous data, so that if no new data is available repeat the stored data
    end
    
    properties (SetAccess = private)
        SerialPort;
        BaudRate = 9600;
    end

    properties(SetAccess = protected, GetAccess = public, Hidden)
        Parent; % this is the hardware object
    end
    
    methods
        function obj = gpsdev(ConnectionObj,varargin)
            try
                if(isa(ConnectionObj, 'matlabshared.sensors.GPSUtilities') &&...
                        isa(ConnectionObj, 'matlabshared.sensors.MultiStreamingUtilities'))
                    availableSerialPorts = ConnectionObj.getAvailableSerialPortIDs();
                else
                    error(message('matlab_sensors:general:invalidHwObjSensor'));
                end
                obj.Parent = ConnectionObj;
                % Set the value of MLStreamingSupported supported
                setIsStreamingSupported(obj);
                p = inputParser;
                p.CaseSensitive = 0;
                p.PartialMatching = 1;
                addParameter(p, 'SerialPort', availableSerialPorts(1));
                % These are the properties associated with MATLAB Streaming
                if(obj.MLStreamingSupported)
                    addParameter(p, 'SamplesPerRead',1);
                    addParameter(p, 'ReadMode', 'latest');
                    addParameter(p, 'OutputFormat','timetable');
                    addParameter(p, 'TimeFormat','datetime');
                end
                parse(p, varargin{:});
                setPropertiesWithStreamingInfo(obj,p.Results);
                obj.SerialPort = p.Results.SerialPort;
                % Depending on the connection object create the association object
                if(isa(obj.Parent, 'matlabshared.sensors.GPSUtilities'))
                    obj.ConnectionObj = matlabshared.sensors.gpsHardware(obj,obj.Parent,obj.MLStreamingSupported,obj.SerialPort,obj.BaudRate);
                else
                    error(message('matlab_sensors:general:invalidHwObjSensor'));
                end
                % During construction an approximate value of Update Rate
                % is calculated.
                obj.UpdateRate = obj.ConnectionObj.UpdateRate;
            catch ME
                props = '''SamplesPerRead'',''ReadMode'',''OutputFormat'' and ''TimeFormat''';
                try
                    getErrorMsg(obj,ME,props);
                catch ME
                    throwAsCaller(ME);
                end
            end
        end
    end
    
    methods(Access = protected)
        function obj = setupImpl(obj)
            if(obj.MLStreamingSupported == 1)
                % For streaming timestamp  is determined by extrapolating time
                obj.startTime = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                % This property is used while checking the time delay between
                % subsequent read
                obj.TimerVal = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss Z');
            end
            obj.ConnectionObj.setup;
        end
        
        function varargout = stepImpl(obj)
            if(obj.MLStreamingSupported == 1)
                if(isequal(lower(string(obj.ReadMode)),'latest'))
                    timeNow = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss Z');
                    % if obj.ToleranceTime has elapsed between 2 calls to
                    % 'step' or between a step and a reset, then clear the
                    % transport buffer and count the number of points trashed.
                    % This is done only for 'latest' buffering mode.
                    if((seconds(timeNow - obj.TimerVal) > obj.ToleranceTime))
                        matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:GPSBuffersFlushed');
                        flushBuffers(obj.ConnectionObj);
                        % This property is checked while calculating
                        % overruns
                        obj.IsFlushBuffers = 1;
                        if(~isempty(obj.PrevData))
                            % RMC Buffer stores the timestamp.The
                            % PrevTimeStamp is stored inorder to calculate
                            % the overruns.This needs to be stored before
                            % clearing the GPS buffers.
                            obj.PrevTimeStamp  = datetime(obj.startTime) + seconds(obj.PrevData(end).TimeStamp);
                        end
                        obj.RMCData = [];
                        obj.GGAData = [];
                        obj.GSAData = [];
                        obj.StoredData = [];
                        obj.StoredTimeStamp = [];
                        obj.PrevData = [];
                    end
                    obj.TimerVal = timeNow;
                end
            end
            % step function of the connection object gives unparsed Data
            [unparsedData, time] = obj.ConnectionObj.step;
            if(obj.MLStreamingSupported == 1)
                index  = strfind(unparsedData,"RMC");
                if(numel(index)>1)
                    % Calculate the Update Rate from the time at which 2
                    % RMC frames are received
                    obj.UpdateRate = [obj.UpdateRate round(1/(time(index(2)) - time(index(1))),2,'significant')];
                    obj.UpdateRate = mean(obj.UpdateRate);
                end
                unparsedData = [obj.StoredData,unparsedData];
                time  = [obj.StoredTimeStamp,time];
                if(strcmp(obj.ReadMode,"latest"))
                    % If many frames are available in frame, discard the
                    % old frames before parsing
                    if(numel(index)>(obj.SamplesPerRead+2))
                        startChar = ['\W[\w*]+','RMC'];
                        startIndex = regexp(unparsedData,startChar);
                        unparsedData = unparsedData(startIndex(end-obj.SamplesPerRead-1):end);
                        time = time(startIndex(end-obj.SamplesPerRead-1):end);
                    end
                end
            end
            [lla,speed, course,dops,utcdatetime,timeStamp,overruns]  = parseAndFrameGpsData(obj,unparsedData,time);
            % update SamplesAvailable value.For Latest Mode, this will be
            % either 1 or 0.Last value is always stored in buffer
            % in case if user tries to read before giving a pause =
            % 1/UpdateRate
            obj.SamplesAvailable = min(numel(obj.RMCData),numel(obj.GGAData));
            if(strcmp(obj.OutputFormat,"matrix"))
                varargout{1} = lla;
                varargout{2} = speed;
                varargout{3} = course;
                varargout{4} = dops;
                varargout{5} = utcdatetime;
                varargout{6} = timeStamp;
                if(obj.MLStreamingSupported==1)
                    varargout{7} = overruns;
                end
            else
                varargout{1} = obj.timeTableOutput;
                if(obj.MLStreamingSupported==1)
                    varargout{2} = overruns;
                end
            end
        end
        
        function resetImpl(obj)
            if(obj.MLStreamingSupported == 1 && ~isempty(obj.RMCData))
                % The last read Timestamp is stored in the buffer which
                % is used for overun calculation
                obj.PrevTimeStamp = datetime(obj.startTime)+seconds(obj.RMCData(end).TimeStamp);
                obj.IsFlushBuffers = 1;
            end
            obj.RMCData = [];
            obj.GGAData = [];
            obj.GSAData = [];
            obj.StoredData = [];
            obj.StoredTimeStamp = [];
            obj.PrevData = [];
            obj.SamplesRead = 0;
            obj.SamplesAvailable = 0;
            obj.ConnectionObj.reset;
        end
        
        function releaseImpl(obj)
            if(isvalid(obj.ConnectionObj))
                obj.ConnectionObj.release;
            end
            obj.PrevData = [];
            obj.RMCData = [];
            obj.GGAData = [];
            obj.GSAData = [];
            obj.StoredData = [];
            obj.StoredTimeStamp = [];
            obj.SamplesRead = 0;
            obj.SamplesAvailable = 0;
            obj.LastReadTime = 0;
        end
        
        function s = infoImpl(obj)
            s = struct('UpdateRate', 1/(obj.UpdateRate),'GPSLocked',obj.GPSLocked,'SatellitesInView',obj.SatellitesInView);
        end
        
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            % properties in dispaly which are specific to interface will be
            % called from the respective classes
            obj.ConnectionObj.showProperties;
            if(obj.MLStreamingSupported == 1)
                fprintf('                     SamplesPerRead: %d\t \n',obj.SamplesPerRead);
                fprintf('                           ReadMode: "%s"\t \n',obj.ReadMode);
                fprintf('                        SamplesRead: %d\t \n',obj.SamplesRead);
                fprintf('                   SamplesAvailable: %d\t \n\n',obj.SamplesAvailable);
            end
            name = inputname(1);
            out  = ['Show <a href="matlab:showAllProperties(' name ')" style="font-weight:bold">all properties</a>',' <a href="matlab:showFunctions(' name ')" style="font-weight:bold">all functions</a>'];
            if ~isempty(out)
                disp(out);
            end
            fprintf('\n');
        end
        
        function setSPFImpl(obj)
            %The number of rows in timetable changes as per SamplesPerRead
            createTimeTableImpl(obj);
        end
        
        function setReadModeImpl(~)
        end
        
        function setOutputFormatImpl(~)
        end
        
        function setTimeFormatImpl(~)
        end
        
        function createTimeTableImpl(obj)
            if(obj.MLStreamingSupported == 1)
                SamplesPerRead = obj.SamplesPerRead;
            else
                SamplesPerRead = 1;
            end
            obj.timeTableOutput = timetable('Size',[SamplesPerRead,numel(obj.DataNames)],'VariableTypes',repmat({'double'},1,numel(obj.DataNames)),'RowTimes',duration(seconds(zeros(SamplesPerRead,1))));
            obj.timeTableOutput.Properties.VariableNames = obj.DataNames;
        end
        
        function value = getSamplesAvailableImpl(obj)
            value =  min([numel(obj.RMCData),numel(obj.GGAData),numel(obj.GSAData)]);
        end
        
        function setPropertiesWithStreamingInfoHook(obj,~)
            if~(obj.MLStreamingSupported)
               createTimeTableImpl(obj);
            end
        end
    end
    
    methods(Access = public)
        function varargout = read(obj)
            %   read(gps); Reads data from the GPS Receiver. read API
            %   returns LLA (Latitude, Longitude and Altitude),Ground Speed,
            %   Course, Dilution of Precisions (PDOP,HDOP,VDOP) and
            %   GPS Receiver time along with timestamps and overruns
            %
            %   If 'OutputFormat' is 'timetable',
            %   [Data, overrun] = read(gps)
            %   'Data' is 'timetable' with fields 'Time' and those
            %   corresponding to the data received from GPS.
            %
            %
            %   If 'OutputFormat' is 'matrix',
            %   [lla, speed, course, dops ,gpsReceiverTime, timeStamp, overrun] = read(gps);
            %   'read' returns matrix outputs for all the quantities.
            %
            %   'overrun' gives the number samples dropped since last read.
            try
                if(isequal(lower(string(obj.OutputFormat)),'timetable'))
                    if(obj.MLStreamingSupported == 1)
                        nargoutchk(0,2) %overrun and timetable
                         [data, overrun] = step(obj);
                    else
                        nargoutchk(0,1) % only timetable
                         data = step(obj);
                    end
                    varargout{1} = data;
                    if(nargout>1)
                        varargout{2} = overrun;
                    end
                else
                    if(obj.MLStreamingSupported == 1)
                        nargoutchk(0,numel(obj.DataNames)+2) % +2 is for overrun and time
                    else
                        nargoutchk(0,numel(obj.DataNames)+1) % +1 for timestamp
                    end
                    varargout = cell(1,numel(obj.DataNames)+2);% +2 is for overrun and time
                    [varargout{:}] = step(obj);
                end
            catch ME
                throwAsCaller(ME)
            end
        end
        
        function writeBytes(obj,configmsg)
            % writeBytes, writes raw commands to GPS receiver.
            try
                % raw Serial accepts bytes. Hence converting the configmsg
                % to uint8.
                if isstring(configmsg)
                    configmsg = char(configmsg);
                end
                if ischar(configmsg)
                    configmsg = uint8(configmsg);
                end
                validateattributes(configmsg, {'char','numeric','string'},{'nonempty','>=',0,'<=',255})
                obj.ConnectionObj.writeBytes(uint8(configmsg));
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function delete(obj)
            try
                obj.Parent = {};
                if(~isempty(obj.ConnectionObj))
                    obj.ConnectionObj.delete
                end
            catch ME
                throwAsCaller(ME);
            end
        end
    end
    
    methods(Access = public, Hidden)
        function showAllProperties(obj)
            obj.ConnectionObj.showProperties;
            if(obj.MLStreamingSupported == 1)
                fprintf('                     SamplesPerRead: %d\t \n',obj.SamplesPerRead);
                fprintf('                           ReadMode: "%s"\t \n',obj.ReadMode);
                fprintf('                        SamplesRead: %d\t \n',obj.SamplesRead);
                fprintf('                   SamplesAvailable: %d\t \n\n',obj.SamplesAvailable);
                fprintf('                       OutputFormat: "%s"\t \n',obj.OutputFormat);
                fprintf('                         TimeFormat: "%s"\t \n\n',obj.TimeFormat);
            end
        end
        
        function showFunctions(obj)
            methodsToDisplay(obj);
        end
        
        function methodsToDisplay(obj)
            % get the built in methods
            methodNames = builtin('methods', obj);
            % remove unwanted methods
            unwantedMethods = {'addlistener','ge','clone','gt','lt','eq','isLocked','ne','reset','findobj','isvalid','notify',...
                'step','findprop','le','listener','delete',class(obj),'gpsdev'};
            if(~obj.MLStreamingSupported)
                unwantedMethods = [unwantedMethods, {'flush'}, {'release'},{'stop'}];
            end
            for i=1:length(unwantedMethods)
                index = strcmp(unwantedMethods{i}, methodNames);
                methodNames(index) = [];
            end
            % Calculate the longest base method name.
            maxLength = max(cellfun('length', methodNames));
            % Calculate spacing information.
            maxColumns = floor(80/maxLength);
            maxSpacing = 2;
            numOfRows = ceil(length(methodNames)/maxColumns);
            % Reshape the methods into a numOfRows-by-maxColumns matrix.
            numToPad = (maxColumns * numOfRows) - length(methodNames);
            methodNames = reshape([methodNames; repmat({' '},[numToPad 1])], numOfRows, maxColumns);
            % Print out the methods.
            for i = 1:numOfRows
                out = '';
                for j = 1:maxColumns
                    m = methodNames{i,j};
                    out = [out sprintf([m blanks(maxLength + maxSpacing - length(m))])]; %#ok<AGROW>
                end
                fprintf([out '\n']);
            end
        end
        
        function  recordStreamingRequest(obj)
            if(isvalid(obj.ConnectionObj))
                obj.ConnectionObj.recordStreamingRequest;
            end
        end
    end
    
    methods(Access = private)
        function [lla,speed, course,dops,utcdatetime,timeStamp,overruns] = parseAndFrameGpsData(obj,rawData,timeStampVal)
            % this fucntion gets the unparsed data and append it to
            % previous non decoded data and calls the parser function.
            % CR (ascii 13) marks the end of the sentence
            endchar  = char(13);
            endidx = strfind(rawData,endchar);
            % if alteast one sentence is present
            if(numel(endidx)>0)
                unParsedData = rawData(1:endidx(end));
                timeStamp =  timeStampVal(1:endidx(end));
                [rmcData,ggaData,gsaData] = matlabshared.sensors.parsePosition(unParsedData,timeStamp);
                if(obj.MLStreamingSupported == 1)
                    % store the characters and time stamp corresponding for
                    % next read.
                    obj.StoredData = rawData(endidx(end)+1:end);
                    obj.StoredTimeStamp = timeStampVal(endidx(end)+1:end);
                end
                % if corresponding Message ID is not found in the rawData,
                % parser returns empty feilds.
                if(~isempty(rmcData(end).Time))
                    obj.RMCData = [obj.RMCData, rmcData];
                end
                if(~isempty(ggaData(end).Time))
                    obj.GGAData =[obj.GGAData, ggaData];
                end
                if(~isempty(gsaData(end).DOPs))
                    obj.GSAData =[obj.GSAData, gsaData];
                end
            else
                if(obj.MLStreamingSupported == 1)
                    % partial data will be stored for next read.
                    obj.StoredData = rawData;
                    obj.StoredTimeStamp = timeStampVal;
                end
            end
            [lla,speed,course,utcdatetime,dops,timeStamp,overruns] = getFrame(obj);
        end
        
        function [lla, speed, course,utcdatetime,dops,timeStamp, overrun] = getFrame(obj)
            if(obj.MLStreamingSupported == 1)
                % timstamp is a double value which is extrapolated with the
                % start time. This is used in streaming mode.
                timeStamp = zeros(obj.SamplesPerRead,1);
                SamplesPerRead = obj.SamplesPerRead;
            else
                SamplesPerRead = 1;
                % system time
                timeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
            end
            lla = nan(SamplesPerRead,3);
            speed=nan(SamplesPerRead,1);
            course = nan(SamplesPerRead,1);
            dops = nan(SamplesPerRead,3);
            gpsLocked = nan(SamplesPerRead,1);
            utcdatetime = NaT(SamplesPerRead,1);
            satellitesInView = nan(SamplesPerRead,1);
            overrun = 0;
            rmcindex = [];
            ggaindex = [];
            % if enough number of Samples are available in GPS buffers,
            % then number of samples to read is SamplesPerRead.Otherwise
            % maximum number of samples that can read is the samples
            % available in the buffer.
            numSamplesToRead = min([SamplesPerRead,numel(obj.RMCData),numel(obj.GGAData),numel(obj.GSAData)]);
            % If atleast one element is present in each buffer, one
            % complete frame could be available
            if(numel(obj.RMCData)>=1 && numel(obj.GGAData)>=1 && numel(obj.GSAData)>=1)
                % Read the time information so as to compare the time given by RMC and GGA sentence,
                % this is required for ensuring sentences are from same Frame
                for i = 1:numel(obj.RMCData)
                    timeRMC(i) = obj.RMCData(i).Time;
                end
                for i = 1:numel(obj.GGAData)
                    timeGGA(i) = obj.GGAData(i).Time;
                end
                timeGGA = timeGGA';
                timeRMC = timeRMC';
                % Make sure the GGA and RMC data are from the same frame by checking the time element
                if(strcmp(obj.ReadMode,"latest"))
                    % determine the start of the RMC frame.
                    if(numel(obj.RMCData) == numSamplesToRead)
                        firstidxRMC = 1;
                    else
                        firstidxRMC = numel(obj.RMCData)- numSamplesToRead+1;
                    end
                    % determine the start of the GGA frame.
                    if(numel(obj.GGAData) == numSamplesToRead)
                        firstidxGGA = 1;
                    else
                        firstidxGGA = numel(obj.GGAData)- numSamplesToRead+1;
                    end
                    try
                        % if the last available set of data in the RMC, GGA buffers
                        % have the same time
                        numOfNonEmptyValuesRMC = nnz(~strcmp(timeRMC(end:-1: firstidxRMC),""));
                        numOfNonEmptyValuesGGA = nnz(~strcmp(timeGGA(end:-1:firstidxGGA),""));
                        expectedNumMatchingElements = min(numOfNonEmptyValuesRMC,numOfNonEmptyValuesGGA);
                        numOfMatchingElements = nnz(strcmp(string(timeRMC(end:-1: firstidxRMC)),string(timeGGA(end:-1:firstidxGGA))));
                        if(expectedNumMatchingElements <= numOfMatchingElements || expectedNumMatchingElements==0)
                            rmcindex = numel(obj.RMCData);
                            ggaindex = numel(obj.GGAData);
                        end
                        if  firstidxRMC>=2
                            numOfNonEmptyValuesRMC = nnz(~strcmp(timeRMC(numel(obj.RMCData)-1:-1:firstidxRMC-1),""));
                            numOfNonEmptyValuesGGA = nnz(~strcmp(timeGGA(numel(obj.GGAData):-1:firstidxGGA),""));
                            expectedNumMatchingElements = min(numOfNonEmptyValuesRMC,numOfNonEmptyValuesGGA);
                            numOfMatchingElements = nnz(strcmp(timeRMC(numel(obj.RMCData)-1:-1: firstidxRMC-1),timeGGA(numel(obj.GGAData):-1:firstidxGGA)));
                            if(expectedNumMatchingElements <= numOfMatchingElements)
                                rmcindex = size(obj.RMCData,2)-1;
                                ggaindex = size(obj.GGAData,2);
                            end
                        end
                        if firstidxGGA >=2
                            numOfNonEmptyValuesRMC = nnz(~strcmp(timeRMC(numel(obj.RMCData):-1: firstidxRMC),""));
                            numOfNonEmptyValuesGGA = nnz(~strcmp(timeGGA(numel(obj.GGAData)-1:-1:firstidxGGA-1),""));
                            expectedNumMatchingElements = min(numOfNonEmptyValuesRMC,numOfNonEmptyValuesGGA);
                            numOfMatchingElements = nnz(strcmp(timeRMC(numel(obj.RMCData):-1: firstidxRMC),timeGGA(numel(obj.GGAData)-1:-1:firstidxGGA-1)));
                            if(expectedNumMatchingElements <= numOfMatchingElements)
                                rmcindex = size(obj.RMCData,2);
                                ggaindex = size(obj.GGAData,2)-1;
                            end
                        end
                    catch
                    end
                    % There is no time parameter to sync for GSA
                    % sentences.Henc give the last available data.
                    gsaindex = numel(obj.GSAData);
                    % Copy the data into matrices
                    if(~isempty(ggaindex) && ~isempty(rmcindex) && ~isempty(gsaindex))
                        idx = 1;
                        for i=ggaindex-numSamplesToRead+1:ggaindex
                            lla(idx,:) = obj.GGAData(i).LLA;
                            satellitesInView(idx,1) =  obj.GGAData(i).SatellitesInView;
                            idx = idx+1;
                        end
                        idx = 1;
                        for i=rmcindex-numSamplesToRead+1:rmcindex
                            speed(idx,1) = obj.RMCData(i).Speed;
                            course(idx,1) = obj.RMCData(i).Course;
                            utcdatetime(idx,1) = obj.RMCData(i).UTCDateTime;
                            timeStamp(idx,1) =  obj.RMCData(i).TimeStamp;
                            gpsLocked(idx,1) =  obj.RMCData(i).GPSLocked;
                            idx = idx+1;
                        end
                        idx = 1;
                        for i=gsaindex-numSamplesToRead+1:gsaindex
                            dops(idx,:) = obj.GSAData(i).DOPs;
                            idx = idx+1;
                        end
                        % store the last read data in PrevData for case
                        % when next read don't have no new sample.
                        obj.PrevData.LLA = lla(idx-1,:);
                        obj.PrevData.SatellitesInView = satellitesInView(idx-1);
                        obj.PrevData.Speed = speed(idx-1);
                        obj.PrevData.Course = course(idx-1,:);
                        obj.PrevData.UTCDateTime = utcdatetime(idx-1);
                        obj.PrevData.TimeStamp = timeStamp(idx-1);
                        obj.PrevData.GpsLocked = gpsLocked(idx-1);
                        obj.PrevData.Dops = dops(idx-1,:);
                        % if enough Number of Samples are not available,repeat the samples
                        if(numSamplesToRead<SamplesPerRead)
                            temp = repmat(lla(idx-1,:),[SamplesPerRead - numSamplesToRead,1]);
                            lla(idx:end,:) = temp;
                            temp = repmat(speed(idx-1),[SamplesPerRead - numSamplesToRead,1]);
                            speed(idx:end) = temp;
                            temp = repmat(course(idx-1),[SamplesPerRead - numSamplesToRead,1]);
                            course(idx:end) = temp;
                            temp = repmat(dops(idx-1,:),[SamplesPerRead - numSamplesToRead,1]);
                            dops(idx:end,:) = temp;
                            temp = repmat(utcdatetime(idx-1),[SamplesPerRead - numSamplesToRead,1]);
                            utcdatetime(idx:end) = temp;
                            temp = repmat(timeStamp(idx-1),[SamplesPerRead - numSamplesToRead,1]);
                            timeStamp(idx:end) = temp;
                            temp = repmat(gpsLocked(idx-1),[SamplesPerRead - numSamplesToRead,1]);
                            gpsLocked(idx:end) =temp;
                            temp = repmat(satellitesInView(idx-1),[SamplesPerRead - numSamplesToRead,1]);
                            satellitesInView(idx:end) =temp;
                        end
                        % clear the buffers
                        obj.RMCData(1:rmcindex)  = [];
                        obj.GGAData(1:ggaindex) = [];
                        obj.GSAData(1:gsaindex) = [];
                        % update overruns
                        overrun = calculateOverrun(obj,timeStamp);
                    end
                else
                    % for oldest mode
                    if(strcmp(obj.RMCData(1).Time,obj.GGAData(1).Time))
                        rmcindex = 1;
                        ggaindex = 1;
                    elseif(size(obj.RMCData,2)>=2 && strcmp(obj.RMCData(2).Time,obj.GGAData(1).Time))
                        rmcindex = 2;
                        ggaindex = 1;
                    elseif(size(obj.GGAData,2)>=2 && strcmp(obj.RMCData(1).Time,obj.GGAData(2).Time))
                        rmcindex = 1;
                        ggaindex = 2;
                    end
                    % no time paramter for GSA so that we can synchronises
                    % between statements. Hence giving out the first
                    % available frames
                    gsaindex = 1;
                    if(~isempty(ggaindex) && ~isempty(rmcindex) && ~isempty(gsaindex))
                        idx = 1;
                        for i= gsaindex: gsaindex+numSamplesToRead-1
                            dops(idx,:) = obj.GSAData(i).DOPs;
                            idx = idx+1;
                        end
                        idx = 1;
                        for i=rmcindex:rmcindex+numSamplesToRead-1
                            speed(idx,1) = obj.RMCData(i).Speed;
                            course(idx,1) = obj.RMCData(i).Course;
                            utcdatetime(idx,1) = obj.RMCData(i).UTCDateTime;
                            timeStamp(idx,1) =  obj.RMCData(i).TimeStamp;
                            gpsLocked(idx,1) =  obj.RMCData(i).GPSLocked;
                            idx = idx+1;
                        end
                        idx = 1;
                        for i=ggaindex:ggaindex+numSamplesToRead-1
                            lla(idx,:) = obj.GGAData(i).LLA;
                            satellitesInView(idx,1) =  obj.GGAData(i).SatellitesInView;
                            idx = idx+1;
                        end
                        % store the previous data, if next read doesnt have
                        % any new samples
                        obj.PrevData.LLA = lla(idx-1,:);
                        obj.PrevData.SatellitesInView = satellitesInView(idx-1);
                        obj.PrevData.Speed = speed(idx-1);
                        obj.PrevData.Course = course(idx-1,:);
                        obj.PrevData.UTCDateTime = utcdatetime(idx-1);
                        obj.PrevData.TimeStamp = timeStamp(idx-1);
                        obj.PrevData.GpsLocked = gpsLocked(idx-1);
                        obj.PrevData.Dops = dops(idx-1,:);
                        
                        if(numSamplesToRead<obj.SamplesPerRead)
                            % if enough Number of Samples are not available,
                            % repeat the samples
                            temp = repmat(lla(idx-1,:),[SamplesPerRead - numSamplesToRead,1]);
                            lla(idx:end,:) = temp;
                            temp = repmat(speed(idx-1),[SamplesPerRead - numSamplesToRead,1]);
                            speed(idx:end) = temp;
                            temp = repmat(course(idx-1),[SamplesPerRead - numSamplesToRead,1]);
                            course(idx:end) = temp;
                            temp = repmat(dops(idx-1,:),[SamplesPerRead - numSamplesToRead,1]);
                            dops(idx:end,:) = temp;
                            temp = repmat(utcdatetime(idx-1),[SamplesPerRead - numSamplesToRead,1]);
                            utcdatetime(idx:end) = temp;
                            temp = repmat(timeStamp(idx-1),[SamplesPerRead - numSamplesToRead,1]);
                            timeStamp(idx:end) = temp;
                            temp = repmat(gpsLocked(idx-1),[SamplesPerRead - numSamplesToRead,1]);
                            gpsLocked(idx:end) = temp;
                            temp = repmat(satellitesInView(idx-1),[SamplesPerRead - numSamplesToRead,1]);
                            satellitesInView(idx:end) = temp;
                        end
                        if(numel(obj.RMCData)>=rmcindex+numSamplesToRead)
                            obj.RMCData = obj.RMCData(rmcindex+numSamplesToRead:end) ;
                        else
                            obj.RMCData =[];
                        end
                        if(numel(obj.GGAData)>=ggaindex+numSamplesToRead)
                            obj.GGAData = obj.GGAData(ggaindex+numSamplesToRead:end);
                        else
                            obj.GGAData=[];
                        end
                        if(numel(obj.GSAData)>=gsaindex+numSamplesToRead)
                            obj.GSAData = obj.GSAData(gsaindex+numSamplesToRead:end);
                        else
                            obj.GSAData=[];
                        end
                    end
                end
                obj.SamplesRead = numSamplesToRead + obj.SamplesRead;
            else
                % if no new sample available, give previos data available
                % in the buffer
                if(~isempty(obj.PrevData) && obj.MLStreamingSupported ==1)
                    lla = ones(SamplesPerRead,1)*obj.PrevData.LLA;
                    satellitesInView = ones(SamplesPerRead,1)*obj.PrevData.SatellitesInView;
                    speed = ones(SamplesPerRead,1)*obj.PrevData.Speed;
                    course = ones(SamplesPerRead,1)*obj.PrevData.Course;
                    utcdatetime = repmat(obj.PrevData.UTCDateTime,SamplesPerRead,1);
                    timeStamp = repmat(obj.PrevData.TimeStamp,SamplesPerRead,1);
                    gpsLocked = ones(SamplesPerRead,1)*obj.PrevData.GpsLocked;
                    dops = ones(SamplesPerRead,1)*obj.PrevData.Dops;
                end
            end
            % This is only used for streaming workflow
            if(obj.IsFlushBuffers == 1 && obj.MLStreamingSupported == 1)
                % If buffers are flushed using reset or due to large time
                % gap between 2 reads.
                obj.IsFlushBuffers = 0;
                currentTime = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                if(timeStamp == 0)
                    timeStamp = zeros(SamplesPerRead,1);
                end
                if(~isempty(obj.UpdateRate))
                    % find approximate value of overrun in this case
                    overrun = abs(round(seconds(currentTime - obj.PrevTimeStamp)/(1/obj.UpdateRate)));
                end
                obj.LastReadTime = seconds(currentTime - obj.startTime);
            end
            utcdatetime = datetime(utcdatetime,'TimeZone','UTC','Format','d-MMM-y HH:mm:ss.SSS');
            if(isequal(lower(string(obj.TimeFormat)),'duration'))
                if(timeStamp~=0)
                    timeStamp = duration(seconds(timeStamp));
                else
                    timeStamp = NaT(SamplesPerRead,1);
                end
            else
                % time format is datetime
                if(obj.MLStreamingSupported == 1)
                    if(timeStamp~=0)
                        timeStamp = datetime(obj.startTime) + seconds(timeStamp);
                    else
                        timeStamp = NaT(SamplesPerRead,1);
                    end
                    timeStamp.TimeZone = 'Local';
                end
            end
            if(strcmp(obj.OutputFormat,"timetable"))
                obj.timeTableOutput.LLA = lla;
                obj.timeTableOutput.GroundSpeed = speed;
                obj.timeTableOutput.Course = course;
                obj.timeTableOutput.DOPs = dops;
                obj.timeTableOutput.GPSReceiverTime = utcdatetime;
                obj.timeTableOutput.Properties.RowTimes = timeStamp;
            end
            obj.GPSLocked = gpsLocked;
            obj.SatellitesInView = satellitesInView;
        end
        
        function numOverrunSamplesSinceLastRead = calculateOverrun(obj,timeStamp)
            numOverrunSamplesSinceLastRead = 0;
            if(obj.MLStreamingSupported == 1)
                numOverrunSamplesSinceLastRead = round(abs(timeStamp(1) -  obj.LastReadTime - 1/obj.UpdateRate)*obj.UpdateRate);
                obj.LastReadTime = timeStamp(end);
            end
        end
    end
end