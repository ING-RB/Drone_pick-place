function [snew, perm] = orderfields(s1,s2)

%   Copyright 1984-2023 The MathWorks, Inc.

if ~isstruct(s1) 
    error(message('MATLAB:orderfields:arg1NotStruct'));
end
if nargin < 2          % ORDERFIELDS(S1)
    % Get sorted s1 fields
    [newfields, perm] = sort(fieldnames(s1));
elseif isnumeric(s2)   % ORDERFIELDS(S1, PERM)
    perm = s2(:);
    newfields = fieldnames(s1);
    n = length(newfields);
    if ( length(perm) ~= n )
        error(message('MATLAB:orderfields:InvalidPermLength'));
    end
    newfields = newfields(perm);
elseif isstruct(s2)   % ORDERFIELDS(S1, S2)
    % Get sorted s1 fields
    [newfields1, perm1] = sort(fieldnames(s1));
    newfields = fieldnames(s2);
    [newfields2, perm2] = sort(newfields);
    if ~all(strcmp(newfields1,newfields2))
        error(message('MATLAB:orderfields:StructFieldMismatch'));
    end
    % perm1 maps original s1 order to alphabetical order
    % perm2 maps original s2 order to alphabetical order
    % invperm2 maps alphabetical order to original s2 order
    % perm1(invperm2) maps original s1 order to original s2 order
    invperm2(perm2) = (1:length(perm2))';
    perm = perm1(invperm2);
elseif iscell(s2) || isstring(s2)  % ORDERFIELDS(S1, C)
    % Get sorted s1 fields
    [newfields1, perm1] = sort(fieldnames(s1));
    [newfields2, perm2] = sort(s2(:));
    if ~all(strcmp(newfields1,newfields2))
        error(message('MATLAB:orderfields:CellStrMismatchFieldnames'));
    end
    % perm1(invperm2) maps original s1 order to original s2 order
    invperm2(perm2) = (1:length(perm2))';
    perm = perm1(invperm2);
    newfields = s2;
else
    error(message('MATLAB:orderfields:InvalidArg2'));
end

% Handle struct arrays
origsize = size(s1);
valuesvector = struct2cell(s1(:));  
valuesvector(:,:) = valuesvector(perm,:);
% create the new struct with the re-ordered fields
snew = cell2struct(valuesvector,cellstr(newfields),1);
snew = reshape(snew,origsize);
