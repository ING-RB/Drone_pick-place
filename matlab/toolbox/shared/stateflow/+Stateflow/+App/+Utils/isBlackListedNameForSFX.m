function ret = isBlackListedNameForSFX(name)
    sfKeywords = {'sf', 'sfx','Stateflow','editor'};
    ret =  any(strcmp(name, sfKeywords)) || exist(name,'builtin') || iskeyword(name);
    if ret
        return;
    end
    % Some of the following keywords are not prohibited by MATLAB to use as
    % variable name but may cause conflicts when used in sfx. black-listing
    % them also just to be on the safe side.
    mlKeywords = {'this','if', 'else', 'case', 'end', 'switch', 'for', 'do', 'while',...
        'break', 'continue', 'return', 'classdef', 'function', 'true', 'false', ...
        'otherwise', 'try', 'catch', 'elseif',...
        'properties', 'function', 'length', 'methods', 'static', 'Public', 'Private',...
        'Constant', 'Protected', 'SetObservable', 'cell', 'strcmp',...
        'public', 'private', 'protected', 'constant', 'varargout', 'varargin', 'nargin'};
    ret = any(strcmp(name, mlKeywords));
end
