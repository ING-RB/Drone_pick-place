function done = handleSimulinkPrinting(pj)
% HANDLESIMULINKPRINTING - internal helper function to handle simulink
% figure for printing process.

%  Copyright 2016-2020 The MathWorks, Inc.

try
    done = false;
    if matlab.graphics.internal.isSLorSF(pj)
        % Printer dialog
        if (ispc() && strcmp(pj.Driver,'setup'))
            eval('SLM3I.SLDomain.showPrintSetupDialog(pj.Handles{1}(1))');
            done = true;
            return;
        end
        
        slprivate('slsf_print', pj);
        done = true;
    end % if(isSLorSF(pj))
catch me
    % We want to see the complete stack in debug mode...
    if(pj.DebugMode)
        rethrow(me);
    else % ...and a simple one in non-debug
        throwAsCaller(me);
    end
end
end
