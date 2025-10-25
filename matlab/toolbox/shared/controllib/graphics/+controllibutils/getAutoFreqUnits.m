function FreqUnits = getAutoFreqUnits(Responses)
%  getAutoFreqUnits  Gets the freq units for first resposne with data
%  source
%

%  Copyright 2016 The MathWorks, Inc.

if isempty(Responses)
    FreqUnits = [];
else
    if isempty(Responses(1).DataSrc)
        % Initial choice is data freq units
        FreqUnits = Responses(1).Data.FreqUnits;
        % Check to see if any other responses has a data source if so use
        % that models frequency units
        for ct = 2:numel(Responses)
            if ~isempty(Responses(ct).DataSrc)
                FreqUnits = getFrequencyUnits(Responses(ct).DataSrc);
                break
            end
        end
    else
       % Use frequency units of data source
       FreqUnits = getFrequencyUnits(Responses(1).DataSrc);
    end
    
end

