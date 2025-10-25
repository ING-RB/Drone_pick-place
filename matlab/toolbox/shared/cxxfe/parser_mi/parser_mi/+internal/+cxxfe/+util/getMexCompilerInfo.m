function varargout = getMexCompilerInfo(varargin)
%GETMEXCOMPILERINFO Returns the current mex compiler settings.
%

%   Copyright 2012-2025 The MathWorks, Inc.

mlock;

persistent cxxCompatInfo;
persistent cCompatInfo;
if isempty(cxxCompatInfo)
    [infoPair, c2CxxCompPair] = getCxxCompToCCompInfoPair();
    infoPair = [infoPair; {'', {'', false, '', {}}}];
    cxxCompatInfo = containers.Map(infoPair(:,1), infoPair(:,2));

    c2CxxCompPair = [c2CxxCompPair; {'', ''}];
    cCompatInfo = containers.Map(c2CxxCompPair(:, 1), c2CxxCompPair(:,2));
end

% Specify the supported input arguments
persistent argParser;
if isempty(argParser)
    argParser = inputParser();
    argParser.addOptional('lang',              'c',   @(x)((ischar(x)||isStringScalar(x)) && any(strcmpi(x,{'c','c++','cxx'}))));
    argParser.addOptional('compInfoFromCoder', [], @(x)(isempty(x) || isa(x, 'mex.CompilerConfiguration')));
    argParser.addOptional('overrideCompilerFlags', '', @(x)(ischar(x)||isStringScalar(x)));
    argParser.addOptional('getCxxCompatInfo', '', @(x)(ischar(x)||isStringScalar(x)));
    argParser.addOptional('getCCompatInfo', '', @(x)(ischar(x)||isStringScalar(x)));
end

% Special case for resetting the cache
if nargin==1 && (ischar(varargin{1}) || isStringScalar(varargin{1})) && ...
        varargin{1}=="clear"
    nargoutchk(0,0);
    internal.cxxfe.mexcfg.clearMexCompilerInfoCache();
    return
end

% Delegate argument checking to the input parser
argParser.parse(varargin{:});

% Use a variable for shorter path access!
args = argParser.Results;
args.lang = convertStringsToChars(args.lang);
args.overrideCompilerFlags = convertStringsToChars(args.overrideCompilerFlags);
args.getCxxCompatInfo = convertStringsToChars(args.getCxxCompatInfo);

if ~isempty(args.getCxxCompatInfo)
    compName = args.getCxxCompatInfo;
    if ~cxxCompatInfo.isKey(compName)
        compName = '';
    end
    info = cxxCompatInfo(compName);
    [varargout{1:nargout}] = info{1:nargout};
    return
end
if ~isempty(args.getCCompatInfo)
    compName = args.getCCompatInfo;
    if ~cCompatInfo.isKey(compName)
        compName = '';
    end
    info = cCompatInfo(compName);
    varargout{1} = info;
    return
end

% Construct the "extractor" options
lang = lower(args.lang);
if (lang == "c++") || (lang == "cxx")
    isC = false;
else
    isC = true;
end
opts = internal.cxxfe.mexcfg.MexCompilerConfigExtractOptions();
if ~isempty(args.overrideCompilerFlags)
    opts.overrideCompilerFlags = args.overrideCompilerFlags;
end
if isC
    opts.lang = internal.cxxfe.mexcfg.LanguageKind.C;
else
    opts.lang = internal.cxxfe.mexcfg.LanguageKind.CXX;
end

% Extract the mex compiler information depending on the strategy
if ~isempty(args.compInfoFromCoder)
    % Special case for SL: the input argument is a structure
    % returned by getCompilerForModel() and it already contains a
    % mex.compilerConfiguration object. The logic below just extract
    % the missing information like the compiler include folders, implicit defines,...
    currCompMap = getPropMap(args.compInfoFromCoder);
    currCompConfig = internal.cxxfe.mexcfg.MexCompilerConfig(currCompMap.keys(), currCompMap.values());
    compInfo = extractCompilerInfo(@()internal.cxxfe.mexcfg.getMexCompilerInfo(opts, currCompConfig));
else
    % Try with the current selected mex compiler
    compInfo = extractCompilerInfo(@()internal.cxxfe.mexcfg.getMexCompilerInfo(opts));
end

if isempty(compInfo) || ~compInfo.isValid()
    if computer('arch') == "win64"
        error(message('MATLAB:mex:NoCompilerFound_Win64'));
    else
        error(message('MATLAB:mex:NoCompilerFound'));
    end
end

if nargout > 0
    varargout{1:nargout} = compInfo;
end

%% ------------------------------------------------------------------------
function compInfo = extractCompilerInfo(callFcn)

% Evaluate the function and "fix" the error identifier as expected by the
% downstream clients (also "MATLAB:mex:Error" is more friendly than
% "cxxfe:mexcfg_msgs:UnexpectedErrorWithExn"...)
try
    compInfo = callFcn();
catch Me
    if Me.identifier == "cxxfe:mexcfg_msgs:UnexpectedErrorWithExn"
        throw(MException('MATLAB:mex:Error', '%s', Me.message));
    else
        rethrow(Me);
    end
end

%% ------------------------------------------------------------------------
function propMap = getPropMap(src, arg)

if nargin == 2
    propMap = arg;
else
    propMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
end

clsInfo = metaclass(src);

for ii = 1:numel(clsInfo.PropertyList)
    propName = clsInfo.PropertyList(ii).Name;
    if ~strcmpi(clsInfo.PropertyList(ii).GetAccess, 'public')
        continue
    end

    if ~isobject(src.(propName))
        propMap(propName) = char(src.(propName));
    else
        getPropMap(src.(propName), propMap);
    end
end

% LocalWords:  lang cxx getCxxCompatInfo getCCompatInfo mexcfg UnexpectedErrorWithExn
