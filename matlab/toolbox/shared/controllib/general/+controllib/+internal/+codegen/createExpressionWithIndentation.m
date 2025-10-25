function Cellstr = createExpressionWithIndentation(Cellstr,Type)
% Utility function to create an indentation for MATLAB Code for Cell string vectors.

% Copyright 2014 The MathWorks, Inc.

% If CellStrVar is 
% A = {'a1'; ...
% 'a2'};
% The function makes
% A = {'a1'; ...
%      'a2'};

if nargin<2
    Type = 'cell';
end

[m,n] = size(Cellstr);

if ~(n==1 || m==1)
    error('Cell string must be a vector');
end

if m>1
    % find the indentation in the first line
    switch Type
        case 'cell'
            str = strsplit(Cellstr{1},'{');  
    end
    identstr = repmat(' ',1,length(str{1})+1);

    % apply indent for other lines
    for ct = 2:m
        Cellstr{ct,1} = sprintf('%s%s',identstr,Cellstr{ct,1});
    end
end