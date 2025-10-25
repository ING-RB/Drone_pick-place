% SIMULINK.SIMULATIONDATA.DATASET.GETELEMENT
%   Get an element or collection of elements from the dataset based
%   on index or name.
%
% INDEX-BASED ACCESS:  
%   If the first argument is a numeric value, the element at this
%   index will be returned.  Only scalar numeric values are supported.
%     >> el = logsout.getElement(1);
%
% NAME-BASED FIND: 
%   If the first argument is a character array, GETELEMENT will search based on
%   Element Name.
%     >> logsout.getElement('my_name')           % returns 1 signal
%     >> logsout.getElement('my_duplicate_name') % returns dataset
%
% RETURNED VALUE:
%   When the first argument is a character array, the returned 
%   value will be a single Element if only 1 element is found or a Dataset 
%   if more than 1 Element of this name exists.
%
%   If the first argument is a cell array containing 1 string, 
%   the returned value will always be a Dataset and may  contain 1 Element.
%     >> ds = logsout.getElement({'my_name'}); % returns dataset

 
%   Copyright 2015-2024 The MathWorks, Inc.

