function checkOutputBlock(x, template, outputArgIndex, suggestLike, varargin)
% Check an output block against a template value. This checks both type and
% small size.
%
% Syntax:
%   checkOutputBlock(x, template, outputArgIndex, suggestLike) checks
%   x against template, ensuring both type and small sizes are the same. If
%   they are different, an error will be issued referencing output argument
%   outputArgIndex. If suggestLike is true and the error could be fixed
%   with "OutputsLike", the error will inform the user.

%   Copyright 2018 The MathWorks, Inc.

% Class names must be the same.
if ~isequal(class(x), class(template))
    iThrow(varargin, suggestLike, ...
        'MATLAB:bigdata:custom:MismatchClass', outputArgIndex, class(x), class(template));
end

% Small sizes must be the same.
xSize = size(x);
likeSize = size(template);
likeSize(1) = xSize(1);
if ~isequal(xSize, likeSize)
    iThrow(varargin, false, ...
        'MATLAB:bigdata:custom:InconsistentSize', outputArgIndex, ...
        iGenerateSizeString(size(x)), iGenerateSizeString(size(template)));
end

if istable(template) || istimetable(template)
    % RowTimes must be the same type.
    if istimetable(template)
        xTime = x.Properties.RowTimes;
        likeTime = template.Properties.RowTimes;
        timeName = template.Properties.DimensionNames{2};
        checkOutputBlock(xTime, likeTime, outputArgIndex, suggestLike, varargin{:}, timeName);
    end
    
    xVarNames = x.Properties.VariableNames;
    xVars = getVars(x, false);
    likeVarNames = template.Properties.VariableNames;
    likeVars = getVars(template, false);
    for ii = 1:numel(likeVars)
        % Variable names must be the same.
        if ~isequal(xVarNames{ii}, likeVarNames{ii})
            iThrow(varargin, suggestLike, ...
                'MATLAB:bigdata:custom:MismatchVarName', outputArgIndex, xVarNames{ii}, likeVarNames{ii});
        end
        
        % Variables must be the same.
        checkOutputBlock(xVars{ii}, likeVars{ii}, outputArgIndex, suggestLike, varargin{:}, likeVarNames{ii});
    end
end
end

function str = iGenerateSizeString(sz)
% Generate a string of the form "Mx2x4x.."
sz = string(sz);
sz(1) = "M";
str = join(sz, char(215));
end

function iThrow(varName, suggestLike, varargin)
% Throw an error. This will:
%  * Switch between Error and ErrorTableVar based on whether we've recursed
%    into table variables.
%  * Append information about "OutputsLike" if requested.
if ~isempty(varName)
    varargin{1} = [varargin{1} 'TableVar'];
    varargin{end + 1} = strjoin(varName, '.');
end
msg = message(varargin{:});
err = matlab.bigdata.BigDataException.build(msg);
if suggestLike
    err = appendToMessage(err, getString(message('MATLAB:bigdata:custom:OutputsLikeSuggestion')), ' ');
end
throw(err);
end
