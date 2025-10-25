classdef gpsdev < matlabshared.gps.internal.SensorHostInterface
    %GPSDEV connects to a GPS receiver connected to the host computer.
    %
    %  gpsObj = gpsdev(port) connects to a GPS receiver on the specified serial port of host computer.
    %  gpsObj = gpsdev(serialObj) connects to a GPS receiver specified by a serial object.
    %  gpsObj = gpsdev(port,Name,Value) connects to a GPS receiver on the specified port/serialObj using one or more name-value pairs.
    %
    %  GPSDEV properties:
    %
    %   ReadMode        -  Options to read either the latest available readings or the values accumulated from the beginning.
    %                      The values are 'latest'(default) or 'oldest'.
    %
    %   SamplesPerRead   - Number of samples per read operation, specified as a positive integer in the range [1 10]. Default value is 1.
    %
    %   OutputFormat     - Format of output data, specified as either 'timetable' (default) or 'matrix'.
    %
    %   TimeFormat       - Format of time stamps, specified as either 'datetime' (default) or 'duration'.
    %
    %   Read only properties:
    %
    %   SamplesAvailable - Number of samples remaining in the buffer waiting to be read.
    %   SamplesRead      - Number of samples read from the sensor.
    %
    %  GPSDEV methods:
    %
    %   read                - Returns one frame each of LLA (latitude,longitude, altitude), ground speed, course, DOPs (PDOP, HDOP, VDOP), and GPS Receiver time
    %                         along with time stamps and overrun.
    %   flush               - Flushes all the data accumulated in the buffers and resets 'SamplesAvailable' and 'SamplesRead'.
    %   writeBytes          - Writes raw commands to GPS module.
    %   info                - Returns GPS Update Rate, Number of Satellites in view that the module can use, and GPS lock information
    %   release             - Release the system object.
    %
    %  Examples
    %    % Connect to a GPS Receiver connected to serial port
    %    g = gpsdev('com4')
    %
    %    % Connect to a GPS Receiver specified by a serial Object
    %    s = serialport('com4',9600)
    %    g = gpsdev(s);
    %
    %    % Connect to a GPS Receiver on the specified port with additional Name-Value options.
    %    g = gpsdev('com4','SamplesPerRead',2,'OutputFormat','matrix','TimeFormat','timetable','ReadMode','oldest');
    %
    %    % Connect to a GPS Receiver specified by a serial object with additional Name-Value options.
    %    s = serialport('com4',115200)
    %    g = gpsdev(s,'SamplesPerRead',2,'OutputFormat','matrix','TimeFormat','timetable','ReadMode','oldest');
    
    %   Copyright 2020-2021 The MathWorks, Inc.
    
    properties(Access = private)
        % To store the unprocessed unparsed data
        StoredUnparsedData = [];
        % To store the parsed RMC, GGA, GSA data
        ParsedRMCData = [];
        ParsedGGAData = [];
        ParsedGSAData = [];
        DataNames = ["LLA","GroundSpeed","Course","DOPs","GPSReceiverTime"]; % Data names to be displayed in the timetable
        GPSLocked = false;
        SatellitesInView = 0;
        % Used to calculate time stamp which is given in output
        SystemTime = [];
        StartTime;
        % Store the last outputted values so as to repeat the same value if
        % user tries to read before new data is available
        PrevData = struct("LLA",[nan,nan,nan],"SatellitesInView",0,"Speed",nan,"Course",nan,"UTCDateTime",NaT,"TimeStamp",NaT,"Dops",[nan,nan,nan],"GpsLocked",false);
        ConnectionObject;
        PrevTime = NaT;
    end
    
    properties(SetAccess = ?matlabshared.gps.internal.gpsTransport)
        BaudRate = 9600;
        SerialPort;
    end
    
    properties(SetAccess = ?matlabshared.gps.internal.gpsTransport,GetAccess = private)
        UpdateRate ;
    end
    
    methods(Access = public)
        function obj = gpsdev(connectionObj,varargin)
            try
                narginchk(1,11);
                p = inputParser;
                p.CaseSensitive = 0;
                p.PartialMatching = 1;
                addParameter(p, 'SamplesPerRead',1);
                addParameter(p, 'ReadMode', 'latest');
                addParameter(p, 'OutputFormat','timetable');
                addParameter(p, 'TimeFormat','datetime');
                addParameter(p, 'BaudRate',9600);
                parse(p, varargin{:});
                % number of arguments passed is excluding the port ID and
                % baud Rate
                numArgs = length(fieldnames(p.Results))*2 - 2;
                setProperties(obj,  numArgs, 'ReadMode',p.Results.ReadMode,.....
                    'SamplesPerRead',p.Results.SamplesPerRead,'OutputFormat',p.Results.OutputFormat,...
                    'TimeFormat',p.Results.TimeFormat);
                obj.BaudRate = p.Results.BaudRate;
                obj.ConnectionObject = matlabshared.gps.internal.gpsTransport(connectionObj,obj);
                %  During construction an approximate value of Update Rate
                %  is calculated.
                if strcmp(obj.OutputFormat,'timetable')
                    createTimeTableImpl(obj);
                end
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function varargout = read(obj)
         %   READ(gpsObj) reads data from the GPS Receiver. The function
            %   returns LLA (Latitude, Longitude and Altitude), Ground Speed,
            %   Course, Dilution of Precisions (PDOP,HDOP,VDOP), and
            %   GPS Receiver time, along with timestamp and overrun.
            %
            %   Syntax:
            %   [data, overrun] = read(gps)
            %   If the 'OutputFormat' of the object is 'timetable', the 'data' output
            %   is a timetable with fields corresponding to the data
            %   received from GPS.
            %
            %   [lla, speed, course, dops, gpsReceiverTime, timeStamp, overrun] = read(gps);
            %   If 'OutputFormat' of the object is 'matrix', the function returns matrix outputs 
            %   for all the quantities.
            %
            %   'overrun' gives the number samples dropped since the last read operation.
            try
                if(strcmp(obj.OutputFormat,"matrix"))
                    nargoutchk(0,numel(obj.DataNames)+2) % +2 is for overrun and time
                    varargout = cell(1,numel(obj.DataNames)+2);
                else
                    nargoutchk(0,2) % overrun and timetable
                    varargout = cell(1,2);
                end
                [varargout{:}] = step(obj);
            catch ME
                throwAsCaller(ME)
            end
        end
        
        function flush(obj)
            % FLUSH(gpsObj) flushes all the data accumulated in the buffers and resets
            %  the 'SamplesAvailable' and 'SamplesRead' properties.
            obj.reset;
        end
        
        function writeBytes(obj,configmsg)
            % WRITEBYTES(gpsObj,configmsg) writes raw commands, specified by configmsg, to the GPS receiver.
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
                obj.ConnectionObject.writeBytes(uint8(configmsg));
            catch ME
                throwAsCaller(ME);
            end
        end
    end
    
    methods(Access = protected)
        function obj = setupImpl(obj)
            obj.StartTime = datetime('now','Format','d-MMM-y HH:mm:ss.SSS');
        end
        
        function varargout = stepImpl(obj)
            % step function of the connection Object gives unparsed Data in
            % string format
            unparsedData = [obj.StoredUnparsedData,obj.ConnectionObject.step];
            % get parsed, synced and formatted(repetitions are taken here) data from raw data
            [lla, speed, course,dops, utcdatetime, timeStamp, overruns]  = getGpsData(obj,unparsedData);
            if strcmp(obj.TimeFormat,'duration')
                % For the first read all the timestamp will be NaT.First read
                % is called after a flush.Hence all the time outputs will be NaT.
                % In case of 'Duration', this should be zero instead of NaT.
                if all(isnat(timeStamp))
                    timeStamp = seconds(zeros(obj.SamplesPerRead,1));
                else
                    timeStamp = abs(seconds(seconds(timeStamp-obj.StartTime)));
                end
            end
            if(strcmp(obj.OutputFormat,"matrix"))
                nargoutchk(0,numel(obj.DataNames)+2) % +2 is for overrun and time
                varargout{1} = lla;
                varargout{2} = speed;
                varargout{3} = course;
                varargout{4} = dops;
                varargout{5} = utcdatetime;
                varargout{6} = timeStamp;
                varargout{7} = overruns;
            else
                nargoutchk(0,2) % overrun and timetable
                obj.timeTableOutput.LLA = lla;
                obj.timeTableOutput.GroundSpeed = speed;
                obj.timeTableOutput.Course = course;
                obj.timeTableOutput.DOPs = dops;
                obj.timeTableOutput.GPSReceiverTime = utcdatetime;
                obj.timeTableOutput.Properties.RowTimes = timeStamp;
                varargout{1} = obj.timeTableOutput;
                varargout{2} = overruns;
            end
        end
        
        function resetImpl(obj)
            obj.ParsedRMCData = [];
            obj.ParsedGGAData = [];
            obj.ParsedGSAData = [];
            obj.StoredUnparsedData = [];
            obj.SystemTime = [];
            obj.PrevTime = obj.PrevData.TimeStamp;
            obj.PrevData = struct("LLA",[nan,nan,nan],"SatellitesInView",0,"Speed",nan,"Course",nan,"UTCDateTime",NaT,"TimeStamp",NaT,"Dops",[nan,nan,nan],"GpsLocked",false);
            obj.SamplesRead = 0;
            obj.SamplesAvailable = 0;
            obj.ConnectionObject.reset;
        end
        
        function releaseImpl(obj)
            if(isvalid(obj.ConnectionObject))
                obj.ConnectionObject.release;
            end
            obj.ParsedRMCData = [];
            obj.ParsedGGAData = [];
            obj.ParsedGSAData = [];
            obj.StoredUnparsedData = [];
            obj.SystemTime = [];
            obj.PrevData = struct("LLA",[nan,nan,nan],"SatellitesInView",0,"Speed",nan,"Course",nan,"UTCDateTime",NaT,"TimeStamp",NaT,"Dops",[nan,nan,nan],"GpsLocked",false);
            obj.SamplesRead = 0;
            obj.SamplesAvailable = 0;
            obj.GPSLocked = false;
            obj.SatellitesInView = 0;
        end
        
        function s = infoImpl(obj)
            if ~isnan(obj.GPSLocked)
                obj.GPSLocked = logical(obj.GPSLocked);
            end
            s = struct("UpdateRate", obj.UpdateRate,"GPSLocked",obj.GPSLocked,"SatellitesInView",obj.SatellitesInView);
        end
        
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            % properties in display which are specific to interface will be
            % called from the respective classes
            obj.ConnectionObject.showProperties;
            fprintf('                     SamplesPerRead: %d\t \n',obj.SamplesPerRead);
            fprintf('                           ReadMode: "%s"\t \n',obj.ReadMode);
            fprintf('                        SamplesRead: %d\t \n',obj.SamplesRead);
            if strcmp(obj.ReadMode, 'oldest')
                fprintf('                   SamplesAvailable: %d\t \n\n',obj.SamplesAvailable);
            end
            % Prepare and display the footer.
            name = inputname(1);
            out  = ['Show <a href="matlab:showAllProperties(' name ')" style="font-weight:bold">all properties</a>',' <a href="matlab:methods(' name ')" style="font-weight:bold">all functions</a>'];
            disp(out);
            fprintf('\n');
        end
        
        function createTimeTableImpl(obj)
            obj.timeTableOutput = timetable('Size',[obj.SamplesPerRead,numel(obj.DataNames)],'VariableTypes',repmat({'double'},1,numel(obj.DataNames)),'RowTimes',duration(seconds(zeros(obj.SamplesPerRead,1))));
            obj.timeTableOutput.Properties.VariableNames = obj.DataNames;
        end
        
        function value = getSamplesAvailableImpl(obj)
            if obj.isLocked
                % start collecting data only if object is unlocked 
                if strcmp(obj.ReadMode, 'oldest')
                    unparsedData = [obj.StoredUnparsedData,obj.ConnectionObject.step];
                    parseData(obj,unparsedData);
                end
            end
            value =  min([numel(obj.ParsedRMCData),numel(obj.ParsedGGAData),numel(obj.ParsedGSAData)]);
        end
    end
    
    methods(Access = private)
        function  [lla, speed, course,dops, utcdatetime, timeStamp, overrun] = getGpsData(obj,rawData)
            % this function gets the unparsed data and return outputs in
            % the form required to construct output
            lla = nan(obj.SamplesPerRead,3);
            speed = nan(obj.SamplesPerRead,1);
            course = nan(obj.SamplesPerRead,1);
            dops = nan(obj.SamplesPerRead,3);
            gpsLocked = nan(obj.SamplesPerRead,1);
            satellitesInView = nan(obj.SamplesPerRead,1);
            utcdatetime = NaT(obj.SamplesPerRead,1); % datetime returned by GPS
            utcdatetime.Format = 'd-MMM-y HH:mm:ss.SSS';
            utcdatetime.TimeZone = 'UTC';
            timeStamp = NaT(obj.SamplesPerRead,1);  % system time
            timeStamp.Format = 'd-MMM-y HH:mm:ss.SSS';
            overrun = 0;
            rmcidx = [];
            ggaidx = [];
            gsaidx = [];
            % appends rawData with previously non decoded data and parse
            % the required sentences.
            parseData(obj,rawData);
            % if enough number of Samples are available in GPS buffers,
            % then number of samples to read is SamplesPerRead.Otherwise
            % maximum number of samples that can read is the minimum number of
            % samples available in the buffer.
            numSamplesToRead = min([obj.SamplesPerRead,numel(obj.ParsedRMCData),numel(obj.ParsedGGAData),numel(obj.ParsedGSAData)]);
            if(numSamplesToRead>=1)
                % This function reads the time information from the
                % sentences and decides the start of frame for each rmc, gga
                % and gsa sentences.This is required for ensuring sentences are from same GPS frame
                [rmcidx,ggaidx,gsaidx,numSamplesToRead] = matlabshared.gps.internal.findStartIndex(obj.ParsedRMCData,obj.ParsedGGAData,obj.ParsedGSAData,obj.ReadMode,numSamplesToRead);
            end
            if(~isempty(ggaidx) && ~isempty(rmcidx) && ~isempty(gsaidx))
                i = ggaidx;
                j = rmcidx;
                k = gsaidx;
                count = 0;
                while(count< numSamplesToRead)
                    count = count+1;
                    lla(count,:) = obj.ParsedGGAData(i).LLA;
                    satellitesInView(count,1) =  obj.ParsedGGAData(i).SatellitesInView;
                    speed(count,1) = obj.ParsedRMCData(j).Speed;
                    course(count,1) = obj.ParsedRMCData(j).Course;
                    utcdatetime(count,1) = obj.ParsedRMCData(j).UTCDateTime;
                    timeStamp(count,1) =  obj.SystemTime(j);
                    gpsLocked(count,1) =  obj.ParsedRMCData(j).GPSLocked;
                    dops(count,:) = obj.ParsedGSAData(k).DOPs;
                    i = i+1;
                    j = j+1;
                    k = k+1;
                end
                % Update overrun
                overrun = getOverrun(obj,timeStamp);
                % store the last read data in PrevData for case
                % when next read don't have no new sample.
                obj.PrevData.LLA = lla(count,:);
                obj.PrevData.SatellitesInView = satellitesInView(count);
                obj.PrevData.Speed = speed(count);
                obj.PrevData.Course = course(count,:);
                obj.PrevData.UTCDateTime = utcdatetime(count);
                obj.PrevData.TimeStamp = timeStamp(count);
                obj.PrevData.GpsLocked = gpsLocked(count);
                obj.PrevData.Dops = dops(count,:);
                % if enough Number of Samples are not available,repeat the samples
                if(numSamplesToRead<obj.SamplesPerRead)
                    temp = repmat(lla(count,:),[obj.SamplesPerRead - numSamplesToRead,1]);
                    lla(count+1:end,:) = temp;
                    temp = repmat(speed(count),[obj.SamplesPerRead - numSamplesToRead,1]);
                    speed(count+1:end) = temp;
                    temp = repmat(course(count),[obj.SamplesPerRead - numSamplesToRead,1]);
                    course(count+1:end) = temp;
                    temp = repmat(dops(count,:),[obj.SamplesPerRead - numSamplesToRead,1]);
                    dops(count+1:end,:) = temp;
                    temp = repmat(utcdatetime(count),[obj.SamplesPerRead - numSamplesToRead,1]);
                    utcdatetime(count+1:end) = temp;
                    temp = repmat(timeStamp(count),[obj.SamplesPerRead - numSamplesToRead,1]);
                    timeStamp(count+1:end) = temp;
                    temp = repmat(gpsLocked(count),[obj.SamplesPerRead - numSamplesToRead,1]);
                    gpsLocked(count+1:end) =temp;
                    temp = repmat(satellitesInView(count),[obj.SamplesPerRead - numSamplesToRead,1]);
                    satellitesInView(count+1:end) =temp;
                end
                % clear the buffers
                obj.ParsedRMCData(1:rmcidx+numSamplesToRead-1)  = [];
                obj.ParsedGGAData(1:ggaidx+numSamplesToRead-1) = [];
                obj.ParsedGSAData(1:gsaidx+numSamplesToRead-1) = [];
                obj.SystemTime(1:rmcidx+numSamplesToRead-1) = [];
                obj.SamplesRead = numSamplesToRead + obj.SamplesRead;
            else
                % if no new sample available, give previous data available
                % in the buffer
                lla = ones(obj.SamplesPerRead,1)*obj.PrevData.LLA;
                satellitesInView = ones(obj.SamplesPerRead,1)*obj.PrevData.SatellitesInView;
                speed = ones(obj.SamplesPerRead,1)*obj.PrevData.Speed;
                course = ones(obj.SamplesPerRead,1)*obj.PrevData.Course;
                utcdatetime = repmat(obj.PrevData.UTCDateTime,obj.SamplesPerRead,1);
                timeStamp = repmat(obj.PrevData.TimeStamp,obj.SamplesPerRead,1);
                gpsLocked = logical(ones(obj.SamplesPerRead,1)*obj.PrevData.GpsLocked);
                dops = ones(obj.SamplesPerRead,1)*obj.PrevData.Dops;
                if ~isnat(obj.PrevTime)
                    currentTime = datetime('now','Format','d-MMM-y HH:mm:ss.SSS');
                    overrun = getOverrun(obj,currentTime);
                    obj.PrevTime = NaT;
                end
            end
            obj.GPSLocked = gpsLocked;
            obj.SatellitesInView = satellitesInView;
        end
        
        function extrapolateAndStoreTimeStamp(obj,numPointsRequired)
            currentTime = datetime('now','Format','d-MMM-y HH:mm:ss.SSS');
            timeVal = (currentTime - (numPointsRequired-1)*seconds(1/obj.UpdateRate)):seconds(1/obj.UpdateRate):currentTime;
            obj.SystemTime = [obj.SystemTime timeVal];
        end
        
        function overrun = getOverrun(obj,timeValue)
            if ~isnat(obj.PrevData.TimeStamp)
                % Difference of one is expected between samples
                overrun = max(round((seconds(timeValue(1)-obj.PrevData.TimeStamp)-1)*obj.UpdateRate),0);
            else
                if ~isnat(obj.PrevTime)
                    % overrun update when a flush a done
                    overrun = max(round((seconds(timeValue(1)-obj.PrevTime)-1)*obj.UpdateRate),0);
                else
                    % overrun update for first read or read after release
                    overrun = max(round((seconds(timeValue(1)-obj.StartTime)-1)*obj.UpdateRate),0);
                end
            end
        end
        
        function parseData(obj,rawData)
            endchar  = char(13); % CR (ascii 13) marks the end of the sentence
            endidx = strfind(rawData,endchar);
            % If at least one complete sentence is present
            if(numel(endidx)>0)
                unParsedData = rawData(1:endidx(end));
                % The character after the last end character belongs to next
                % sentence.This characters are stored and appended in next
                % read.
                obj.StoredUnparsedData = rawData(endidx(end)+1:end);
                [rmcdata,ggadata,gsadata] = matlabshared.gps.internal.parsePosition(unParsedData);
                % if corresponding Message ID is not found in the rawData,
                % parser returns empty fields.
                if(~isempty(rmcdata(end).Time))
                    obj.ParsedRMCData = [obj.ParsedRMCData,rmcdata];
                    % to get time parameter for the time table.For number of
                    % data in the structure, time is extrapolated using
                    % update frame and stored in an array
                    extrapolateAndStoreTimeStamp(obj,numel(rmcdata));
                end
                if(~isempty(ggadata(end).Time))
                    obj.ParsedGGAData =[obj.ParsedGGAData, ggadata];
                end
                if(~isempty(gsadata(end).DOPs))
                    obj.ParsedGSAData =[obj.ParsedGSAData, gsadata];
                end
            else
                % partial data will be stored for next read.
                obj.StoredUnparsedData = rawData;
            end
        end
    end
    
    methods(Access = public, Hidden)
        function showAllProperties(obj)
            obj.ConnectionObject.showProperties;
            fprintf('                     SamplesPerRead: %d\t \n',obj.SamplesPerRead);
            fprintf('                           ReadMode: "%s"\t \n',obj.ReadMode);
            fprintf('                        SamplesRead: %d\t \n',obj.SamplesRead);
            if strcmp(obj.ReadMode, 'oldest')
                fprintf('                   SamplesAvailable: %d\t \n\n',obj.SamplesAvailable);
            end
            fprintf('                       OutputFormat: "%s"\t \n',obj.OutputFormat);
            fprintf('                         TimeFormat: "%s"\t \n\n',obj.TimeFormat);
        end
    end
end