function [RMCData,GGAData,GSAData] = parsePosition(inData,time)

%  Copyright 2019-2020 The MathWorks, Inc.
inData = char(inData);
endChar = 13;
seperator = ',';
RMCData = struct('Time','',"Speed",'',"Course",'',"UTCDateTime",'','GPSLocked','',"TimeStamp",'');
GGAData = struct('Time','',"LLA",'','SatellitesInView',"");
GSAData = struct('DOPs','');

[dataRMCUnparsed,NoOfRMCmsgs,status,timeStamp] = preprocessGPSData(inData,'RMC',endChar,time);
if(status == 1)
    rmc_idx = 1;
    timermc = strings(NoOfRMCmsgs,1);
    speed = nan(NoOfRMCmsgs,1);
    course = nan(NoOfRMCmsgs,1);
    gpslocked = nan(NoOfRMCmsgs,1);
    utcdatetime = strings(NoOfRMCmsgs,1);
    while(rmc_idx<=NoOfRMCmsgs)
        [timermc(rmc_idx),speed(rmc_idx),course(rmc_idx),utcdatetime(rmc_idx),gpslocked(rmc_idx)] = parseRMC(dataRMCUnparsed{rmc_idx});
        RMCData(rmc_idx).Time = (timermc(rmc_idx));
        RMCData(rmc_idx).Speed = speed(rmc_idx);
        RMCData(rmc_idx).Course = course(rmc_idx);
        RMCData(rmc_idx).UTCDateTime = utcdatetime(rmc_idx);
        RMCData(rmc_idx).TimeStamp = timeStamp(rmc_idx);
        RMCData(rmc_idx).GPSLocked = gpslocked(rmc_idx);
        rmc_idx=rmc_idx+1;
    end
end

[dataGGAUnparsed,NoOfGGAmsgs,status,~] = preprocessGPSData(inData,'GGA',endChar,time);
if(status == 1)
    gga_idx = 1;
    timegga = strings(NoOfGGAmsgs,1);
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

[dataGSAUnparsed,NoOfGSAmsgs,status,~] = preprocessGPSData(inData,'GSA',endChar,time);
if(status == 1)
    gsa_idx = 1;
    dops = zeros(NoOfGSAmsgs,3);
    while(gsa_idx<=NoOfGSAmsgs)
        dops(gsa_idx,:)  = parseGSA(dataGSAUnparsed{gsa_idx});
        GSAData(gsa_idx).DOPs = dops(gsa_idx,:);
        gsa_idx = gsa_idx+1;
    end
end

    function [unParsedData,noOfMsgs,status,timeStamp] = preprocessGPSData(inData,messageID,endChar,time)
        % Check if message ID is present in the input
        status = 0;
        % Device id could be different for GNSS recievers.For example GP is
        % for GPS, GN is for GLONASS.But Message ID will remain the same
        startChar = ['\W[\w*]+',messageID];
        startIndex = regexp(inData,startChar);
        endindex = strfind(inData,endChar);
        i=1;
        noOfMsgs = numel(startIndex);
        unParsedData = cell(1,noOfMsgs);
        timeStamp = time(startIndex);
        while(i<= noOfMsgs)
            idx = startIndex(i);
            % if there are multiple end Characters in the given data,
            % consider the endcharacter after the startCharacter
            endidx = endindex(endindex>idx);
            unParsedData{i} = inData(idx:endidx(1));
            i= i+1;
            status = 1;
        end
    end

    function [time,speed,course,utcdatetime,gpslocked] = parseRMC(dataRMCUnparsed)
        time = "";
        speed = nan;
        course = nan;
        utcdatetime = "";
        gpslocked="";
        index = strfind(dataRMCUnparsed,seperator);
        time_idx = 1;
        status_idx = 2;
        speed_idx = 7;
        course_idx =8;
        date_idx = 9;
        RMC_ChecksumIdx = strfind(dataRMCUnparsed,'*');
        checksum = char(dataRMCUnparsed(RMC_ChecksumIdx+1:RMC_ChecksumIdx+2));
        validity = validateData(dataRMCUnparsed,checksum);
        if(validity == 1)
            gpslocked = dataRMCUnparsed(index(status_idx)+1:index(status_idx+1)-1);
            if(strcmp(gpslocked,'A'))
                gpslocked = true;
            elseif(strcmp(gpslocked,'V'))
                gpslocked = false;
            end
            if(gpslocked == true)
                time = dataRMCUnparsed(index(time_idx)+1:index(time_idx+1)-1);
                if(~isempty(time))
                    time = char([time(1:2),':',time(3:4),':',time(5:end)]);
                end
                
                speed = dataRMCUnparsed(index(speed_idx)+1:index(speed_idx+1)-1);
                course = dataRMCUnparsed(index(course_idx)+1:index(course_idx+1)-1);
                % speed obtained is in knots, convert this to m/s
                speed = str2double(speed)*0.51444444444;
                course = str2double(course);
                date = dataRMCUnparsed(index(date_idx)+1:index(date_idx+1)-1);
                if(~isempty(date))
                    date= char(['20',date(5:6),'-',date(3:4),'-', date(1:2)]);
                    utcdatetime  = [date,' ',time];
                end
            end
        else
            matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:wrongChecksum','RMC');
        end
    end

    function  [lla,time,satelitesinview] = parseGGA(dataGGAUnparsed)
        index = strfind(dataGGAUnparsed,seperator);
        % If fix or data is not available, GPS recievers output empty
        % feilds.
        time_idx = 1;
        lat_idx = 2;
        long_idx = 4;
        satelitesinview_idx = 7;
        fixQuality_idx = 6;
        alt_idx = 9;
        time = "";
        lla = [nan,nan,nan];
        
        GGA_ChecksumIdx = strfind(dataGGAUnparsed,'*');
        checksum = char(dataGGAUnparsed(GGA_ChecksumIdx+1:GGA_ChecksumIdx+2));
        validity = validateData(dataGGAUnparsed,checksum);
        satelitesinview = str2double(dataGGAUnparsed(index(satelitesinview_idx)+1:index(satelitesinview_idx+1)-1));
        if(validity == 1)
            fixQuality = dataGGAUnparsed(index(fixQuality_idx)+1:index(fixQuality_idx+1)-1);
            if(str2double(fixQuality)~=0)
                time = dataGGAUnparsed(index(time_idx)+1:index(time_idx+1)-1);
                if(~isempty(time))
                    time = char([time(1:2),':',time(3:4),':',time(5:end)]);
                end
                latitude = dataGGAUnparsed(index(lat_idx)+1:index(lat_idx+1)-1);
                latitudeD = dataGGAUnparsed(index(lat_idx+1)+1:index(lat_idx+2)-1);
                if(~isempty(latitude)|| ~isempty(latitudeD))
                    latitude = convertLatLong(latitude);
                    if(strcmp(latitudeD(1),'S'))
                        latitude = -1*latitude;
                    end
                end
                longitude = dataGGAUnparsed(index(long_idx)+1:index(long_idx+1)-1);
                longitudeD = dataGGAUnparsed(index(long_idx+1)+1:index(long_idx+2)-1);
                if(~isempty(longitude) || ~isempty(longitudeD))
                    longitude = convertLatLong(longitude);
                    if(strcmp(longitudeD(1),'W'))
                        longitude = -1*longitude;
                    end
                end
                satelitesinview = str2double(dataGGAUnparsed(index(satelitesinview_idx)+1:index(satelitesinview_idx+1)-1));
                if(~isempty(dataGGAUnparsed(index(alt_idx)+1:index(alt_idx+1)-1)))
                    altitude_msl = str2double(dataGGAUnparsed(index(alt_idx)+1:index(alt_idx+1)-1));
                    geoid = str2double(dataGGAUnparsed(index(alt_idx+2)+1:index(alt_idx+3)-1));
                    altitude = altitude_msl + geoid;
                    lla=[latitude,longitude,altitude];
                end
            end
        else
            matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:wrongChecksum','GGA');
        end
    end

    function  dops = parseGSA(dataGSAUnparsed)
        index = strfind(dataGSAUnparsed,seperator);
        % If fix or data is not available, GPS recievers output empty
        % feilds.
        dops = [nan,nan,nan];
        GSA_ChecksumIdx = strfind(dataGSAUnparsed,'*');
        checksum = char(dataGSAUnparsed(GSA_ChecksumIdx+1:GSA_ChecksumIdx+2));
        validity = validateData(dataGSAUnparsed,checksum);
        pdop_idx = 15;
        hdop_idx = 16;
        vdop_idx = 17;
        fix_idx = 2;
        if(validity == 1)
            fix = str2double(dataGSAUnparsed(index(fix_idx)+1:index(fix_idx+1)-1));
            if(fix~=1)
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
            matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:wrongChecksum','GSA');
        end
    end


% Function to extract and convert latitude and longitude into degrees
    function LatLong = convertLatLong(data)
        idx = strfind(data,'.');
        % The lat and lon is of format ddmm.mmm. Two digits before decimal
        % point is always starting of minutes
        tempfraction = (str2double(data(idx-2:end))/60);
        tempInt = str2double(data(1:idx-3));
        temp = tempInt+tempfraction;
        LatLong = temp;
    end

% Function to check if the checksum matches
    function validity = validateData(data,Checksum)
        calculated_checksum = 0;
        % The String inbetween "$" and "*" is considered for checksum
        % calulation
        NMEA_Data = uint16(strtok(data,'*'));
        % checkusm is calculate excluding $ and * in GPS sentences.
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


