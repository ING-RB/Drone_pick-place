function [deployable, why] = isdeployable(files, varargin)
%

%   Copyright 2012-2020 The MathWorks, Inc.

narginchk(1,3)
validateattributes(files,{'cell','char'},{},1)

% files should be a cell array of strings. As a special case, allow a
% single file name string (wrap it in a cell array).
if ischar(files) 
    files = { files };
end

% Default values for optional inputs.
entryPoint = false;
target = 'None';

% Process optional arguments. Distinguish them by data type.
setEntryPoint = false;
setTarget = false;
for k = 1:numel(varargin)
    validateattributes(varargin{k},{'char','logical'},{},k+1)
    if islogical(varargin{k})
        if setEntryPoint
            error(message('MATLAB:depfun:req:DoubleEntryPoint', ...
                'isdeployed', string(entryPoint), string(varargin{k})))
        end
        entryPoint = varargin{k};
        setEntryPoint = true;
    else
        % Must be a char
        if setTarget
            error(message('MATLAB:depfun:req:TwiceToldTarget', ...
                'isdeployed', target, varargin{k}))
        end
        target = varargin{k};
        setTarget = true;
    end
end

% Parse the target string to a member of the Target enumeration.
tgt = matlab.depfun.internal.Target.parse(target);
if (tgt == matlab.depfun.internal.Target.Unknown)
    error(message('MATLAB:depfun:req:BadTarget', target))
end

% Create a Completion to do the real work. Turn off the warning about all
% files being excluded from the root set -- but restore its state 
% before returning.
rsw = warning('off', 'MATLAB:depfun:req:AllInputsExcluded');
c = matlab.depfun.internal.Completion(tgt);
warning(rsw.state, rsw.identifier);

[deployable, why] = isdeployable(c, files, entryPoint);

% LocalWords:  lang
