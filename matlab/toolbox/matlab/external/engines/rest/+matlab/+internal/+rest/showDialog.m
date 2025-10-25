function retVal = showDialog()
    yStr    = message('MATLAB:restFcnService:YesButton').getString;
    nStr    = message('MATLAB:restFcnService:NoButton').getString;
    wStr    = message('MATLAB:restFcnService:WarningText').getString;
    m       = message('MATLAB:restFcnService:RemoteAccessConfirmation', yStr);
    answer  = questdlg(m.getString, wStr, nStr, yStr, nStr);
    
    switch answer
        case yStr
            retVal = true;
        case nStr
            retVal = false;
        otherwise
            retVal = false;
    end
end
