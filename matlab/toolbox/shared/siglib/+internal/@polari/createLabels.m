function createLabels(p,varargin)
%createLabels Write formatted data to Labels property.
%   createLabels(P,FORMAT,A,...) creates and stores a
%   cell-vector of strings in the Labels property, by applying
%   the FORMAT string to all elements of array A and any
%   additional array arguments in column order.
%
%   To learn about FORMAT strings, refer to the sprintf
%   function.
%
%   Example: Generate labels with unique values in each
%     p = polarpattern(rand(30,4),'Style','filled');
%     createLabels(p,'az=%d#deg',0:15:45)
%

argSlices = internal.polariCommon.createArgSets(varargin{:});
p.LegendLabels = internal.polariCommon.fevalArgSets(@sprintf,argSlices);
