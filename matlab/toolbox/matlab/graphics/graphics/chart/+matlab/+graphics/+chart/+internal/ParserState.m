classdef ParserState < uint32
    %PARSERSTATE Summary of this class goes here
    %   Detailed explanation goes here

    % Numbers MUST differ by 10 in the order of execution
    enumeration
        Start (10)
        ParsedParent (20)
        ParsedFlag(30)
        ParsedNameValue(40)
        ParsedTrailingFlags(50)
        ParsedConvenienceArgs(60)
        End(70)
    end
    
    methods(Access=public, Static, Hidden=true)
        % For internal use only.
        function val = getPrev(thisEnum)
            val = matlab.graphics.chart.internal.ParserState(max(thisEnum - 10, matlab.graphics.chart.internal.ParserState.Start));
        end
    end
end

