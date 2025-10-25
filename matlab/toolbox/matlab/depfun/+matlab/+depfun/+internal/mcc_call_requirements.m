function [parts, resources, unpackaged_parts, flags, errors] = mcc_call_requirements(items, tgt, varargin)
% A wrapper over requirements, called from mcc

% Copyright 2016-2021 The MathWorks, Inc.

import matlab.depfun.internal.requirementsSettings
import matlab.depfun.internal.requirementsConstants

[parts, resources, unpackaged_parts, errors] = deal({});
flags = struct('isJavaRequired', false, 'isFakeHgrcRequired', false);
orgDataDetec = requirementsSettings.isDataDetectionOn;
%If target is WebApp, set webAppFlag to true and set tgt to MCR to be ready
%for matlab.depfun.internal.requirements function input
webAppFlag = false;
if strcmp(tgt,'WebApp_MCR')
    webAppFlag = true;
    tgt='MCR';
end
try
    %Adding matlabrc.m, printopt.m, and startup to CTF. 
    %Previously these special files are passed when mcc_call_requirements is called through items argument.
    specialFiles = {'matlabrc.m', 'printopt.m'};
    %
    % Restrict startup to startup.p or startup.m on the MATLAB path.
    %
    if exist('startup.p','file')==6
        startupFile = 'startup.p';
    else if exist('startup.m','file')==2
            startupFile = 'startup.m';
        else
            startupFile = '';
        end
    end
    if ~isempty(startupFile)
        startupFile = which(startupFile);
    end
    specialFiles = [specialFiles, startupFile];    
    %This accounts for the extremely specific case in which the compiler calls
    %requirements and the X argument is passed. Only the compiler can toggle
    %auto_data_dependency off. Compiler never sends path arguments, those
    %are done separately.  It might pass -Z info through, so we remove the
    %-X.
    reqinputs = varargin;
    Xidx = strcmp(reqinputs,'-X');
    if any(Xidx)
        %If the X flag shows up in that exact position it means requirements
        %was called from c++ and data dependency is to be turned off
        requirementsSettings.setDataDetection(false);
        reqinputs(Xidx) = [];
    else
        requirementsSettings.setDataDetection(true);
    end
    
    %Return settings variable to original value
    resetRequirementsSettings = ...
    onCleanup(@()requirementsSettings.setDataDetection(orgDataDetec));
    
    items = [items, specialFiles];
    [parts, resources, unpackaged_parts] = matlab.depfun.internal.requirements(items, tgt, reqinputs{:});
    %check for web app multi-window limitation and print warning
    if webAppFlag
        matlab.depfun.internal.webAppLimitationCheck(parts,unpackaged_parts.expected);
    end
    pid_runtime = [resources.products.ProductNumber];
    flags.isJavaRequired = ~isempty(intersect(requirementsConstants.mcrProductsNeedJVM, pid_runtime));
    flags.isFakeHgrcRequired = isempty(intersect(requirementsConstants.mcrProductsNeedHG, pid_runtime));
catch ex
    % The mcc user does not need to see the MATLAB stack trace, so
    % issue a basic report instead of the default, which would be
    % an extended report.
    errors = getReport(ex, 'basic');
end

end

% LocalWords:  jre
