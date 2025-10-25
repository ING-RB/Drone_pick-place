function [appDesignEnvironment, varargout] = getAppDesignEnvironment(componentAdapterMap, appDesignerModelAlreadyCreated, createIfNotExist)
%GETAPPDESIGNENVIRONMENT Internal function to guarantee only one 
% App Designer will be launched
%
% GETAPPDESIGNENVIRONMENT uses local persistent variable to make sure
% only one instance of AppDesignEnvironment through the MATLAB sessionn

% Copyright 2015 - 2017 The MathWorks, Inc.

% Make the AppDesignEnvironment have only one instance via 
% a persistent variable

arguments
    componentAdapterMap = [];
    appDesignerModelAlreadyCreated = [];
    createIfNotExist = true;
end

narginchk(0, 3);
nargoutchk(0, 2);

nout = max(nargout, 1) - 1;
if nout == 1
    varargout{1} = [];
end

persistent localAppDesignEnvironment;
if isempty(localAppDesignEnvironment) || ~isvalid(localAppDesignEnvironment)
    % First time starting App Designer, localAppDesignEnvironment would be 
    % empty. 
    % After closing App Designer, localAppDesignEnvironment would be
    % invalid when launching App Designer again
    
    if createIfNotExist
        % the AppDesignEnvironment
        [localAppDesignEnvironment, ~] = appdesigner.internal.application.createAppDesignEnvironment(componentAdapterMap, appDesignerModelAlreadyCreated);
    else
        appDesignEnvironment = [];
        return;
    end
end

appDesignEnvironment = localAppDesignEnvironment;
if nout == 1
    varargout{1} = appDesignEnvironment.AppDesignerModel;
end

% put a lock on the instance so this instance cannot be cleared by a
% "clear all".  If not "clear all" would close the App Designer
mlock;

end

