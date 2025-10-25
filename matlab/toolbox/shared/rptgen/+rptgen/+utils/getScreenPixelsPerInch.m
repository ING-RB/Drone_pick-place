function ppi = getScreenPixelsPerInch()
% Returns screen pixels per inch.  In headless mode, returns 96

%   Copyright 2015-2023 The MathWorks, Inc.
    
    persistent PPI
    
    if isempty(PPI)
        if (isprop(0, 'TerminalProtocol') && ~strcmpi(get(0, 'TerminalProtocol'),'x'))
            PPI = 96;
        else
            PPI = get(0, 'ScreenPixelsPerInch');
        end
    end
    
    ppi = PPI;
end