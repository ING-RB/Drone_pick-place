function [RMCData,GGAData,GSAData] = parsePosition(inData)
% parsePosition function parses input GPS NMEA data to give structures corresponding to
% RMC, GGA and GSA data. RMC structure consist of Time, Speed,Course, GPS
% Lock, and UTC date time which are extracted from RMC sentence.GGA
% structure consist of Time, Satellites in view and LLA which are parsed
% from GGA sentence and GSA structure consist of DOPs.

% Copyright 2020-2023 The MathWorks, Inc.
inData = char(inData);
% endChar is CR
endChar = 13;
seperator = ',';
RMCData = struct("Time",'',"Speed",'',"Course",'',"UTCDateTime",'','GPSLocked','');
GGAData = struct("Time",'',"LLA",'','SatellitesInView','');
GSAData = struct("DOPs",'');

[dataRMCUnparsed,NoOfRMCmsgs,status] = preprocessGPSData(inData,'RMC');
% preprocessGPSData returns status 1, indicating required MSG ID is found
if(status == 1)
    rmc_idx = 1;
    timermc = NaT(NoOfRMCmsgs,1);
    timermc.Format = 'HH:mm:ss.SSS';
    speed = nan(NoOfRMCmsgs,1);
    course = nan(NoOfRMCmsgs,1);
    gpslocked = nan(NoOfRMCmsgs,1);
    utcdatetime = NaT(NoOfRMCmsgs,1);
    utcdatetime.Format = 'd-MMM-y HH:mm:ss.SSS';
    utcdatetime.TimeZone = 'UTC';
    while(rmc_idx<=NoOfRMCmsgs)
        [timermc(rmc_idx),speed(rmc_idx),course(rmc_idx),utcdatetime(rmc_idx),gpslocked(rmc_idx)] = parseRMC(dataRMCUnparsed{rmc_idx});
        RMCData(rmc_idx).Time = (timermc(rmc_idx));
        RMCData(rmc_idx).Speed = speed(rmc_idx);
        RMCData(rmc_idx).Course = course(rmc_idx);
        RMCData(rmc_idx).UTCDateTime = utcdatetime(rmc_idx);
        RMCData(rmc_idx).GPSLocked = gpslocked(rmc_idx);
        rmc_idx=rmc_idx+1;
    end
end

[dataGGAUnparsed,NoOfGGAmsgs,status] = preprocessGPSData(inData,'GGA');
% preprocessGPSData returns status 1, indicating required MSG ID is found
if(status == 1)
    gga_idx = 1;
    timegga = NaT(NoOfGGAmsgs,1);
    timegga.Format = 'HH:mm:ss.SSS';
    lla = zeros(NoOfGGAmsgs,3);
    SatellitesInView = zeros(NoOfGGAmsgs,1);
    while(gga_idx<=NoOfGGAmsgs)
        [lla(gga_idx,:),timegga(gga_idx+1),SatellitesInView(gga_idx)]  = parseGGA(dataGGAUnparsed{gga_idx});
        GGAData(gga_idx).Time = (timegga(gga_idx+1));
        GGAData(gga_idx).LLA = lla(gga_idx,:);
        GGAData(gga_idx).SatellitesInView = SatellitesInView(gga_idx);
        gga_idx = gga_idx+1;
    end
end

[dataGSAUnparsed,NoOfGSAmsgs,status] = preprocessGPSData(inData,'GSA');
% preprocessGPSData returns status 1, indicating required MSG ID is found
if(status == 1)
    gsa_idx = 1;
    dops = zeros(NoOfGSAmsgs,3);
    while(gsa_idx<=NoOfGSAmsgs)
        dops(gsa_idx,:)  = parseGSA(dataGSAUnparsed{gsa_idx});
        GSAData(gsa_idx).DOPs = dops(gsa_idx,:);
        gsa_idx = gsa_idx+1;
    end
end

    function [unParsedData,noOfMsgs,status] = preprocessGPSData(inData,messageID)
        % Check if message ID is present in the input and returns the lines
        % corresponding to the message ID
        status = 0;
        % Device ID could be different for GNSS receivers.For example GP is
        % for GPS, GN is for GLONASS.But Message ID will remain the
        % same.
        startChar = ['\W[\w*]+',messageID];
        startIndex = regexp(inData,startChar);
        endindex = strfind(inData,endChar);
        i=1;
        noOfMsgs = numel(startIndex);
        unParsedData = cell(1,noOfMsgs);
        while(i<= noOfMsgs)
            idx = startIndex(i);
            % if there are multiple end characters in the given data,
            % consider the end character after the start character   
            endidx = endindex(endindex>idx);
            unParsedData{i} = inData(idx:endidx(1));
            i= i+1;
            status = 1;
        end
    end

    function [time,speed,course,utcdatetime,gpslocked] = parseRMC(dataRMCUnparsed)
        % parse RMC sentence to get time, speed, course, date, GPS lock
        time = NaT;
        time.Format = 'HH:mm:ss.SSS';
        speed = nan;
        course = nan;
        utcdatetime = NaT;
        utcdatetime.Format = 'd-MMM-y HH:mm:ss.SSS';
        utcdatetime.TimeZone = 'UTC';
        gpslocked=nan;
        index = strfind(dataRMCUnparsed,seperator);
        % index of the fields are fixed for RMC sentences
        time_idx = 1;
        status_idx = 2;
        speed_idx = 7;
        course_idx =8;
        date_idx = 9;
        % Checksum field is 2 character after * in NMEA sentence
        RMC_ChecksumIdx = strfind(dataRMCUnparsed,'*');
        checksum = char(dataRMCUnparsed(min(RMC_ChecksumIdx)+1:min(RMC_ChecksumIdx)+2));
        % checks if calculated checksum is same as obtained checksum
        validity = validateData(dataRMCUnparsed,checksum);
        if(validity == 1)
            gpslocked = dataRMCUnparsed(index(status_idx)+1:index(status_idx+1)-1);
            % A stands for Active indicate GPS Lock is available
            if(strcmp(gpslocked,'A'))
                gpslocked = 1;
                % V stands for void indicating no GPS lock.
            elseif(strcmp(gpslocked,'V'))
                gpslocked = 0;
            end
            if(gpslocked == true)
                time = dataRMCUnparsed(index(time_idx)+1:index(time_idx+1)-1);
                if(~isempty(time))
                    timeNotConverted = char([time(1:2),':',time(3:4),':',time(5:end)]);
                    time = datetime(timeNotConverted,'Format','HH:mm:ss.SSS');
                end
                speed = dataRMCUnparsed(index(speed_idx)+1:index(speed_idx+1)-1);
                course = dataRMCUnparsed(index(course_idx)+1:index(course_idx+1)-1);
                % speed obtained is in knots, convert this to m/s
                speed = str2double(speed)*0.51444444444;
                course = str2double(course);
                date = dataRMCUnparsed(index(date_idx)+1:index(date_idx+1)-1);
                if(~isempty(date))
                    date= char(['20',date(5:6),'-',date(3:4),'-', date(1:2)]);
                    utcdatetime  = datetime([date,' ',timeNotConverted],'Format','d-MMM-y HH:mm:ss.SSS','TimeZone','UTC');
                end
            end
        else
            warning(message('shared_gps:general:WrongChecksum','RMC'));
        end
    end

    function  [lla,time,satelitesinview] = parseGGA(dataGGAUnparsed)
        % Parse RMC sentence to get LLA, Time and Satellites in view
        index = strfind(dataGGAUnparsed,seperator);
        time = NaT;
        time.Format = 'HH:mm:ss.SSS';
        lla = [nan,nan,nan];
        satelitesinview = nan;
        % Index of fields are fixed for GGA sentences
        time_idx = 1;
        lat_idx = 2;
        long_idx = 4;
        satelitesinview_idx = 7;
        fixQuality_idx = 6;
        alt_idx = 9;
        % Check sum field is 2 character after * in NMEA sentence
        GGA_ChecksumIdx = strfind(dataGGAUnparsed,'*');
        checksum = char(dataGGAUnparsed(min(GGA_ChecksumIdx)+1:min(GGA_ChecksumIdx)+2));
        % checks if calculated checksum is same as obtained checksum
        validity = validateData(dataGGAUnparsed,checksum);
        if(validity == 1)
            satelitesinview = str2double(dataGGAUnparsed(index(satelitesinview_idx)+1:index(satelitesinview_idx+1)-1));
            fixQuality = dataGGAUnparsed(index(fixQuality_idx)+1:index(fixQuality_idx+1)-1);
            % fix quality 0 implies no Satellite fix is available
            if(str2double(fixQuality)~=0)
                time = dataGGAUnparsed(index(time_idx)+1:index(time_idx+1)-1);
                if(~isempty(time))
                    time = char([time(1:2),':',time(3:4),':',time(5:end)]);
                    time = datetime(time,'Format','HH:mm:ss.SSS');
                end
                latitude = dataGGAUnparsed(index(lat_idx)+1:index(lat_idx+1)-1);
                latitudeD = dataGGAUnparsed(index(lat_idx+1)+1:index(lat_idx+2)-1);
                latitude = convertLatLong(latitude);
                if(strcmp(latitudeD(1),'S'))
                    latitude = -1*latitude;
                end
                longitude = dataGGAUnparsed(index(long_idx)+1:index(long_idx+1)-1);
                longitudeD = dataGGAUnparsed(index(long_idx+1)+1:index(long_idx+2)-1);
                longitude = convertLatLong(longitude);
                if(strcmp(longitudeD(1),'W'))
                    longitude = -1*longitude;
                end
                if(~isempty(dataGGAUnparsed(index(alt_idx)+1:index(alt_idx+1)-1)))
                    altitude_msl = str2double(dataGGAUnparsed(index(alt_idx)+1:index(alt_idx+1)-1));
                    geoid = str2double(dataGGAUnparsed(index(alt_idx+2)+1:index(alt_idx+3)-1));
                    altitude = altitude_msl + geoid;
                    lla=[latitude,longitude,altitude];
                end
            end
        else
            warning(message('shared_gps:general:WrongChecksum','GGA'));
        end
    end

    function  dops = parseGSA(dataGSAUnparsed)
        % Parse GSA sentence to get DOPs
        index = strfind(dataGSAUnparsed,seperator);
        dops = [nan,nan,nan];
        % Index of fields are fixed for GSA sentences
        pdop_idx = 15;
        hdop_idx = 16;
        vdop_idx = 17;
        fix_idx = 2;
        GSA_ChecksumIdx = strfind(dataGSAUnparsed,'*');
        checksum = char(dataGSAUnparsed(min(GSA_ChecksumIdx)+1:min(GSA_ChecksumIdx)+2));
        validity = validateData(dataGSAUnparsed,checksum);
        if(validity == 1)
            fix = str2double(dataGSAUnparsed(index(fix_idx)+1:index(fix_idx+1)-1));
            if(fix~=1)
                % If fix or data is not available, GPS receivers output empty
                % fields.
                PDOP = str2double(dataGSAUnparsed(index(pdop_idx)+1:index(pdop_idx+1)-1));
                HDOP = str2double(dataGSAUnparsed(index(hdop_idx)+1:index(hdop_idx+1)-1));
                if(numel(index)== vdop_idx)
                    end_idx = GSA_ChecksumIdx;
                else
                    end_idx = index(vdop_idx);
                end
                VDOP = str2double(dataGSAUnparsed(index(vdop_idx)+1:end_idx-1));
                dops = [PDOP,HDOP,VDOP];
            end
        else
            warning(message('shared_gps:general:WrongChecksum','GSA'));
        end
    end

% Function to extract and convert latitude and longitude into degrees
    function LatLong = convertLatLong(data)
        LatLong = nan;
        if ~isempty(data)
            idx = strfind(data,'.');
            % The lat and lon is of format ddmm.mmm. Two digits before decimal
            % point is always starting of minutes
            if ~isempty(idx)
                tempfraction = (str2double(data(idx-2:end))/60);
                tempInt = str2double(data(1:idx-3));
            else
                % if no decimal point
                tempfraction = real(str2double(data(end-1:end))/60);
                tempInt = real(str2double(data(1:end-2)));
            end
            temp = tempInt+tempfraction;
            LatLong = temp;
        end
    end

% Function to check if the checksum matches
    function validity = validateData(data,Checksum)
        calculated_checksum = 0;
        % The string in between "$" and "*" is considered for checksum
        % calculation
        NMEA_Data = uint16(strtok(data,'*'));
        % checksum is calculate excluding $ and * in GPS sentences.
        for count = 2:length(NMEA_Data)
            calculated_checksum = bitxor(calculated_checksum ,NMEA_Data(count));  % checksum calculation
        end
        % convert checksum to hex value
        calculated_checksum  = dec2hex(calculated_checksum);
        % add leading zero to checksum if it is a single digit.
        if (length(calculated_checksum ) == 1)
            calculated_checksum  = strcat('0',calculated_checksum);
        end
        % Check if the calculated checksum is equal to the obtained
        % checksum
        if(strcmp(calculated_checksum,Checksum))
            validity  = 1;
        else
            validity  = 0;
        end
    end
end
