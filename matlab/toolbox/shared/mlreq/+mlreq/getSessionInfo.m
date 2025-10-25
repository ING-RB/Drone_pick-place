function [hasReqmgt, hasSlreq, mlRoot] = getSessionInfo(callerId)

    % This is meant to be called from MATLAB Editor to determine whether
    % to initialize Requirements Traceability plugins.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    hasReqmgt = isSharedReqmgtInstalled();
    
    if hasReqmgt
        hasSlreq = isSlreqEditAvailable(callerId);
        mlRoot = matlabroot();
        if ~endsWith(mlRoot, filesep)
            % prefer /MALTAB/ instead of /MATLAB to avoid accidental
            % match with /MATLAB Drive/... contents, see g2943250 
            mlRoot = [mlRoot filesep];
        end
    else
        hasSlreq = false;
        mlRoot = 'NOT-USED';
    end
    
end

function tf = isSharedReqmgtInstalled()
    % As of R2021b shared_reqmgt is installed with base Simulink.
    % MATLAB Test is another possible way in, but this is not released yet.
    tf = isfolder([matlabroot '/toolbox/shared/reqmgt/']) && contains(path, ['shared' filesep 'reqmgt']);
    % note that SL license does not matter, just need the files and MATLAB path entry
end

function tf = isSlreqEditAvailable(callerId)

    % If callerId is an SID of an implicit MLFB, return false, because we
    % cannot allow to modify Req. Links attached behind active lib. link.
    if rmisl.isSidString(callerId)
        try
            isFromLib = rmisl.isActiveLibRefSID(callerId);
            if isFromLib
                tf = false;
                return;
            end
        catch
            % probably diagram not loaded
            % it is safer to disallow link editing
            tf = false; return;
        end
    end
    
    % For all other situations, simply confirm Requirements Product is available 
    [slreqInstalled, slreqLicensed] = rmi.isInstalled();
    tf = slreqInstalled && slreqLicensed;
end
