function fmt = verifyFormat(fmt) %#codegen
%VERIFYFORMAT Validate duration format.
%   FMT = VERIFYFORMAT(FMT) returns the validated format.

%   Copyright 2014-2020 The MathWorks, Inc.

if matlab.internal.coder.datatypes.isCharString(fmt)   
    if any(strcmp(fmt,{'y','d','h','m','s','dd:hh:mm:ss','hh:mm:ss','mm:ss','hh:mm'}))
        return
    else
        % Only the first three options support fractional seconds.
        timerFormats = {'dd:hh:mm:ss','hh:mm:ss','mm:ss'};
        matchedOption =[startsWith(fmt,timerFormats{1}), startsWith(fmt,timerFormats{2}), startsWith(fmt,timerFormats{3})];
        coder.internal.assert(any(matchedOption),'MATLAB:duration:UnrecognizedFormat',fmt);
        
        fmtLength = strlength(fmt);
        timerLength = strlength(timerFormats);
        for i = 1:3
            if matchedOption(i) && (fmtLength >  timerLength(i))
                % Check everything after the decimal. 
                fractionalPart = fmt((timerLength(i)+1):end);
                % Optional fractional seconds up to 9S
                if ~(fractionalPart(1)=='.' && all(fractionalPart(2:end)=='S') && strlength(fractionalPart) < 11)
                    coder.internal.error('MATLAB:duration:UnrecognizedFormat',fmt)
                end
            end
        end
    end
else
    coder.internal.assert(false,'MATLAB:duration:InvalidFormat');
end
