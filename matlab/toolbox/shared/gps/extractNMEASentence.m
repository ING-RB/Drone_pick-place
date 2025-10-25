function [valid,splitString] = extractNMEASentence(data,messageID)
%extractNMEASentence Extracts NMEA fields from a NMEA sentence
%   [isValid, nmeaFields] = extractNMEASentence(data,messageID)
%   extracts NMEA fields from the NMEA sentence 'data' for the 
%   specified 'messageID' into a string array nmeaFields. It also
%   verifies the checksum of the NMEA sentence, 'isValid' populates to
%   logical one for a valid checksum zero otherwise
%   
%
%   Example:
%   rmcRawData = ['$GPRMC,111357.771,A,5231.364,N,01324.240,E,1090'...
%                 '3,221.5,020620,000.0,W*6A'];
%   [isValid, rmcData] = extractNMEASentence(rmcRawData,"RMC")
%
%   See also NMEAPARSER

%   Copyright 2020-2021 The MathWorks, Inc.

valid = false ;
splitString = "";

if( (~(isa(data, 'string') || isa(data, 'char')) )|| (~(isa(messageID, 'string') || isa(messageID, 'char')) ))
   return; 
end

if isa(data, 'string')
    data = char(data);
end

if isa(messageID, 'string')
    messageID = char(messageID);
end

if(validateNMEASentence(data,messageID))
    valid = matlabshared.gps.internal.calculateCSValidity(data);
else
    return;
end
extractedData = extractBetween(data, [messageID,  ','], '*');
splitString = split(string(extractedData{1}),',');

if~(data(2)=='P')
   TalkerID = data(2:3);  
   splitString = [string(TalkerID), string(messageID), splitString(:)'];   
else
   splitString = [string(messageID), splitString(:)'];      
end
    
end

%Verify a valid nmeaSentence
function valid = validateNMEASentence(data, messageID)
valid = false;

if(~isempty(data) && data(1)~='$')
    return;
end

if(numel(data) > 2)
    data = data(2:end);
else
    return;
end

if(numel(data) > 3)

    if(data(1)=='P')
        % Proprietary Sentence
        % Skip one character
        data = data(2:end);
    else
        % NMEA sentence
        % Skip two characters
        data = data(3:end);
    end
else
    return;
end

if(~contains(data,messageID))
    return;
end

data = extractAfter(data,messageID);

if(~contains(data,'*'))
    return
end

data = extractAfter(data,'*');

if(length(data)<2)
    return;
end

hexRange =  ['0':'9','A':'F'];
if ~all(ismember(data(1:2),hexRange))
    return;
end



valid = true;

end

