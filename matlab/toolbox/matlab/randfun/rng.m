function settings = rng(arg1,arg2)
%   Syntax:
%      rng("default")
%      rng(seed)
%      rng(seed,generator)
%      rng(generator)
%      rng(s)
%      t = rng
%      t = rng(___)
%
%   For more information, see documentation

%   Copyright 2010-2024 The MathWorks, Inc.

if nargin == 0 || nargout > 0
    % With no inputs, settings will be returned even when there's no outputs
    s = RandStream.getGlobalStream();
    if strcmpi(s.Type,'legacy')
        settings = struct('Type','Legacy','Seed',legacySeedStr(),'State',{s.State});
    else
        settings = struct('Type',RandStream.compatName(s.Type),'Seed',s.Seed,'State',{s.State});
    end
end

if nargin > 0
    arg1 = convertStringsToChars(arg1);
    if isempty(arg1)
        % If the first input is empty (even if char) then we can't know if
        % a generator or seed was intended. Throw the more general error.
        error(message('MATLAB:rng:badFirstOpt'));
    end
    if isstruct(arg1) && isscalar(arg1)
        inSettings = arg1;
        if nargin > 1
            error(message('MATLAB:rng:maxrhs'));
        elseif ~isempty(setxor(fieldnames(inSettings),{'Type','Seed','State'}))
            throw(badSettingsException);
        end
        if strcmpi(inSettings.Type,'legacy')
            handleLegacyStruct(inSettings); % restores the legacy stream state
        else
            % Create a new stream as specified, then set its state
            try
                s = RandStream(inSettings.Type,'Seed',inSettings.Seed);
                s.State = inSettings.State;
            catch me
                throw(badSettingsException);
            end
            RandStream.setGlobalStream(s);
        end
    else
        if isnumeric(arg1) && isscalar(arg1) % rng(seed) or rng(seed,gentype)
            seed = arg1;
            if nargin == 1
                gentype = getCurrentType;
            else
                arg2 = convertStringsToChars(arg2);
                gentype = arg2;
                if ~ischar(gentype)
                    error(message('MATLAB:rng:badSecondOpt'));
                elseif strcmpi(gentype,'legacy')
                    errorLegacyGenType;
                end
            end
        elseif ischar(arg1)
            if strcmpi(arg1,'shuffle') % rng('shuffle') or rng('shuffle',gentype)
                seed = RandStream.shuffleSeed;
                if nargin == 1
                    gentype = getCurrentType;
                else
                    arg2 = convertStringsToChars(arg2);
                    gentype = arg2;
                    if ~ischar(gentype)
                        error(message('MATLAB:rng:badSecondOpt'));
                    elseif strcmpi(gentype,'legacy')
                        errorLegacyGenType;
                    end
                end
            elseif strcmpi(arg1,'default') % rng('default')
                if nargin > 1
                    error(message('MATLAB:rng:maxrhs'));
                end
                % The default is guaranteed valid so just set and return
                RandStream.restoreDefaultGlobalStream();
                return;
            elseif nargin == 1
                % Flags are exact-matched above, so assume rng(gentype).
                % RandStream also requires exact match for these.
                gentype = arg1;
                seed = 0;
            else % possibly rng(gentype,seed)
                error(message('MATLAB:rng:badFirstOptWithTwoOpts'));
            end
        else
            error(message('MATLAB:rng:badFirstOpt'));
        end
        
        % Create a new stream using the specified seed
        try
            s = RandStream(gentype,'Seed',seed); % RandStream handles the compatibility names
        catch me
            if strcmp(me.identifier,'MATLAB:RandStream:create:UnknownRNGType')
                error(message('MATLAB:rng:unknownRNGType',gentype));
            elseif strcmp(me.identifier,'MATLAB:RandStream:BadSeed')
                error(message('MATLAB:rng:badSeed'));
            else
                throw(me);
            end
        end
        RandStream.setGlobalStream(s);
    end
end


% This function allows a caller to save and restore legacy stream state
% structure even when MATLAB is switched out of legacy mode in between the
% saving and restoring.
function handleLegacyStruct(s)
% If the struct appears valid, activate the legacy stream, and set
% its state(s) from the struct.
if isequal(s.Seed,legacySeedStr()) % the legacy stream struct does not store a seed
    rand('state',0); %#ok<RAND>
    legacy = RandStream.getGlobalStream();
    try
        legacy.State = s.State;
    catch me % the state field must have been altered
        throwAsCaller(badSettingsException);
    end
else % the seed field must have been altered
    throwAsCaller(badSettingsException);
end


function e = badSettingsException
e = MException('MATLAB:rng:badSettings',getString(message('MATLAB:rng:badSettings')));


function str = legacySeedStr
str = 'Not applicable';


function gentype = getCurrentType
curr = RandStream.getGlobalStream();
gentype = curr.Type;
if strcmpi(gentype,'legacy')
    % Disallow reseeding when in legacy mode, even with a zero seed
    suggestion = RandStream.compatName(matlab.internal.math.getFactoryDefaultRandStreamType());
    throwAsCaller(MException('MATLAB:rng:reseedLegacy',getString(message('MATLAB:rng:reseedLegacy',suggestion))));
end

% Disallow specifying 'legacy' as a generator type, even with a zero seed
function errorLegacyGenType
suggestion = RandStream.compatName(matlab.internal.math.getFactoryDefaultRandStreamType());
throwAsCaller(MException('MATLAB:rng:createLegacy',getString(message('MATLAB:rng:createLegacy',suggestion))));
