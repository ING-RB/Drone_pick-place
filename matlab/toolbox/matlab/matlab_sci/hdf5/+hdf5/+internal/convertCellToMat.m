function res = convertCellToMat(data)
%CONVERTCELLTOMAT Convert a cell array into a matrix.
% This custom helper is needed because CELL2MAT does not work with MCOS
% objects.
% Old cell2mat return a empty double if the cell is empty.Mimic-ing
% cell2mat behavior in order to be compatible with legacy HDF5 API.

% Author: Upanita Goswami
% Copyright 2017 The MathWorks Inc

if isempty(data)
    res=[];
    return;
end
 
% If the cell array contains native types, then use the built-in CELL2MAT
if ~isa(data{1}, 'hdf5.hdf5type')
    res = cell2mat(data);
    return;
end

[row,col] = size(data);
for i = 1: row
    for j = 1: col
        res(i,j)= data{i,j}; %#ok<AGROW>
    end
end