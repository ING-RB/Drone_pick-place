function [TF,msg] = checkOneDriveFileAvailability(fileName)
%read 1 byte of data using BinaryStream to verify if file is available
%on disk/downloadable through onedrive file system on windows. If onedrive 
% is offline, 'read' will throw an error.

% Copyright The MathWorks, Inc. 2024

    TF=true;
    msg="";
    charFileName = convertStringsToChars(fileName);
    try
        binStream=matlab.io.internal.vfs.stream.createStream(charFileName);
        data=binStream.read(1,'uint8');
    catch ME
        TF=false;
        msg=ME.message;
        if endsWith(msg,".")
            %remove the fullstop at the end as images:hdrread:fileOpen has
            %a fullstop
            msg=extractBetween(msg,1,strlength(msg)-1);
            msg=msg{1};
        end
    end
    if exist('binStream','var')
        delete(binStream);
    end
end