function sentenceParserObj = getSentenceParser(msgID)
% Function returns the object of the parser classes depending on the
% message ID

%   Copyright 2020 The MathWorks, Inc.
    switch msgID
      case "RMC"
        sentenceParserObj = matlabshared.gps.internal.NMEASentenceParserRMC;
      case "GGA"
        sentenceParserObj = matlabshared.gps.internal.NMEASentenceParserGGA;
      case "GSA"
        sentenceParserObj = matlabshared.gps.internal.NMEASentenceParserGSA;
      case "HDT"
        sentenceParserObj = matlabshared.gps.internal.NMEASentenceParserHDT;
      case "ZDA"
        sentenceParserObj = matlabshared.gps.internal.NMEASentenceParserZDA;
      case "GLL"
        sentenceParserObj = matlabshared.gps.internal.NMEASentenceParserGLL;
      case "GST"
        sentenceParserObj = matlabshared.gps.internal.NMEASentenceParserGST;
      case "VTG"
        sentenceParserObj = matlabshared.gps.internal.NMEASentenceParserVTG;
      case "GSV"
        sentenceParserObj = matlabshared.gps.internal.NMEASentenceParserGSV;
      otherwise
        % If the user tries to add a new sentence which is not in the
        % listed.This is an internal error.
        error(message('shared_gps:general:InvalidMessageID'));
    end
end

% LocalWords:  gps
