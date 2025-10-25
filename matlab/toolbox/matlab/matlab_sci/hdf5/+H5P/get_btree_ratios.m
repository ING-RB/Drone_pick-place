function [left, middle, right] = get_btree_ratios(plist_id)
%H5P.get_btree_ratios  Return B-tree split ratios.
%   [left middle right] = H5P.get_btree_ratios(plist_id) returns the B-tree
%   split ratios for the dataset transfer property list specified by
%   plist_id. left specifies the B-tree split ratio for left-most nodes;
%   right for the right-most nodes and lone nodes, and middle for all other
%   nodes.
%
%   Example:
%       dxpl = H5P.create('H5P_DATASET_XFER');
%       [left,middle,right] = H5P.get_btree_ratios(dxpl);
%
%   See also H5P, H5P.get_btree_ratios.

%   Copyright 2006-2024 The MathWorks, Inc.

[left, middle, right] = matlab.internal.sci.hdf5lib2(...
    'H5Pget_btree_ratios', plist_id);            
