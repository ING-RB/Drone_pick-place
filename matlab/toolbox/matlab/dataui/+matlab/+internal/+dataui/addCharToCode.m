function funCall = addCharToCode(funCall,funParameter,isIndented)
% addCharToCode: Helper for performing tasks in a Live Script
% This function will add new N-V pair or parameter to function call code and
% insert a line break if the resulting code is too wide.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2023 The MathWorks, Inc.

if nargin < 3
    isIndented = false;
end
lineBreak = '';
if ~isempty(funParameter)
    nlind = strfind(funCall,newline);
    if isempty(nlind)
        % no newline yet, start at beginning of funCall
        nlind = 0;
    end
    % Move the comma to the previous row
    if isequal(funParameter(1),',')
        lineBreak = [',' lineBreak];
        funParameter(1) = [];
    end
    % Start new line if new width is greater than 80 characters
    lastRowWidth = numel(funCall(nlind(end)+1:end));
    if lastRowWidth + numel(funParameter) > 80
        lineBreak = [lineBreak ' ...' newline '    '];
        if isIndented
            lineBreak = [lineBreak '    '];
        elseif isequal(funParameter(1),' ')
            % We had 'oldS, newS' and we are putting newS on a new line
            % Remove the extra space
            funParameter(1) = [];
        end
    end
end
funCall = [funCall lineBreak funParameter];
end