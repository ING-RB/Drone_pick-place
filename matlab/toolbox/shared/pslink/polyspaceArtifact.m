function generatedArtifacts = polyspaceArtifact(varargin)
% POLYSPACEARTIFACT - Generate polyspace analysis artifacts.
% 
%     ARTIFACTS = POLYSPACEARTIFACT() generate polyspace 
%     analysis artifacts on the current system using the configuration
%     associated with the system. The absolute path of generated artifact
%     files is returned in ARTIFACTS.
% 
%     ARTIFACTS = POLYSPACEARTIFACT(MODEL) generate polyspace
%     analysis artifacts on the MODEL.
%     Polyspace uses the configuration options associated with the system 
%     that contains MODEL.
%  
%     ARTIFACTS = POLYSPACEARTIFACT(MODEL, OPTS) generate Polyspace
%     analysis artifacts on the MODEL using the configuration
%     specified in the optional second argument OPTS, which is a pslinkoptions
%     object.
%
%     ARTIFACTS = POLYSPACEARTIFACT(MODEL, OPTS, ASMDLREF)
%     generate Polyspace artifacts on the MODEL by using the
%     configuration specified in the pslinkoptions object OPTS.
%     The third optional argument ASMDLREF indicates whether to consider
%     the generated code as a model reference or not.
%     If ASMDLREF is false (default), the Polyspace artifacts are generated
%     considering a standalone code. If ASMDLREF is true, the Polyspace artifacts
%     are generated on a referenced model code.
%
%     ARTIFACTS = POLYSPACEARTIFACT(MODEL, OPTS, ASMDLREF, ARTIFACTS)
%     generate the specified Polyspace artifacts, it must be an array (possibly empty) of
%     the following case-insensitive values:
%     1. 'drs': Generate the data range specification file for the specified
%     model.
%     2. 'linksdata': Generate a file containing the model on the MODEL using the configuration
%     specified in the optional second argument OPTS, which is a pslinkoptions
%     object.
%     If empty, then it generates all the aforementioned Polyspace
%     artifacts.
%
%   See also PSLINKOPTIONS.


% Copyright 2023 The MathWorks, Inc.

parserObj = inputParser;
parserObj.addOptional('modelName', bdroot, @(x) (isstring(x) && isscalar(x)) || ischar(x));
parserObj.addOptional('opts', [], @(x) isa(x, 'pslink.Options') || isempty(x));
parserObj.addOptional('isTopMdlRefAnalysis', false, @(x) islogical(x));
parserObj.addOptional('artifacts', {}, @(x) iscellstr(x) || isempty(x));
parserObj.parse(varargin{:});

modelName = char(parserObj.Results.modelName);
opts = parserObj.Results.opts;
isTopMdlRefAnalysis = parserObj.Results.isTopMdlRefAnalysis;
if isempty(modelName)
    error('pslink:missingArgument', DAStudio.message('polyspace:gui:pslink:missingArgument', 'modelName'));
end

[~, systemH] = checkSystemValidity(modelName, true);
coderID = getCoderID(systemH);
if isempty(coderID)
    msg = message('polyspace:gui:pslink:systemNotConfiguredForSupportedCoder', getfullname(systemH)).getString();
    Me = MException('pslink:systemNotConfiguredForSupportedCoder', msg);
    throwAsCaller(Me);
end
if strcmp(coderID, pslink.verifier.sfcn.Coder.CODER_ID)
    meObj = MException('pslink:unsupportedPolyspaceArtifact', ...
                       message('polyspace:gui:pslink:unsupportedPolyspaceArtifact').getString());
    throwAsCaller(meObj);
end

artifacts = parserObj.Results.artifacts;
generatedArtifacts =  prepareCodeVerification(systemH, opts, coderID, isTopMdlRefAnalysis, artifacts);

end
