function tf = local_ismember(elem, list)
%   This function is for internal use only. It may be removed in the future.
%LOCAL_ISMEMBER codegen compatible ismember. Works with list as a cell
%   array. Not a drop in replacement for ismember. Returns a scalar true or
%   false if the char vector ELEM is in the cell array of char vectors
%   LIST. 

%   Copyright 2021 The MathWorks, Inc.    

%#codegen

tf = false;
for ii=1:numel(list)
    tf = tf | strcmp(elem, list{ii});
end
end