classdef LoggingStream < matlab.automation.streams.OutputStream
    % OutputStream that logs all text sent to it
    
    % Copyright 2012-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Log;
    end
    
    properties (SetAccess=private)
        FormattableLog matlab.automation.internal.diagnostics.FormattableString = '';
    end
    
    methods
        function print(stream, formatStr, varargin)
            stream.FormattableLog = stream.FormattableLog + sprintf(formatStr, varargin{:});
        end
        
        function printFormatted(stream, formattableStr)
            stream.FormattableLog = stream.FormattableLog + formattableStr;
        end
        
        function clearContent(stream)
            stream.FormattableLog = '';
        end
        
        function txt = get.Log(stream)
            txt = char(stream.FormattableLog);
        end
    end
end

% LocalWords:  Formattable formattable
