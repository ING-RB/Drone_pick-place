function set_file_space_strategy(fcpl_id,strategy,is_persist,threshold)
%H5P.set_file_space_strategy  Sets the file space handling strategy.
%   H5P.set_file_space_strategy(fcpl_id,strategy,is_persist,threshold) sets
%   the file space handling strategy and persisting free-space values for 
%   file creation property list fcpl_id.  
%   strategy is the file space handling strategy to be used and can be
%   specified by one of the following strings or their numeric equivalents:
%     H5F_FSPACE_STRATEGY_FSM_AGGR
%     H5F_FSPACE_STRATEGY_PAGE
%     H5F_FSPACE_STRATEGY_AGGR
%     H5F_FSPACE_STRATEGY_NONE
%   is_persist is a boolean value to indicate whether free space should be persistent or not.  
%   threshold is the smallest free-space section size that the free space manager will track. 
%
%   Example:
%         filename = 'sample.h5';
%         faplID = H5P.create('H5P_FILE_ACCESS');
%         fcplID = H5P.create('H5P_FILE_CREATE');                   
%         % Using FSM Aggregators
%         H5P.set_file_space_strategy(fcplID,H5ML.get_constant_value('H5F_FSPACE_STRATEGY_FSM_AGGR'),true,1);
%         [actStrat,actPersist,actThresh] = H5P.get_file_space_strategy(fcplID);
%         % Create the file
%         H5P.set_libver_bounds(faplID,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST');
%         fileID = H5F.create(filename,'H5F_ACC_TRUNC',fcplID,faplID);
%         H5F.close(fileID);
%         H5P.close(faplID);
%         H5P.close(fcplID);
%
%   See also H5P, H5P.get_file_space_strategy.

%   Copyright 2024 The MathWorks, Inc.

validateattributes(fcpl_id, {'H5ML.id'}, {'nonempty', 'scalar'});
if (ischar(strategy) || isstring(strategy)) 
    strategy = convertStringsToChars(strategy);
    validateattributes(strategy,{'char'},{'nonempty', 'scalartext'}, '', 'strategy');
elseif isnumeric(strategy)
    validateattributes(strategy,{'double'}, {'nonempty', 'scalar', 'finite', 'integer'}, '', 'strategy');
else
    error(message('MATLAB:imagesci:hdf5lib:badEnumInputType'));
end
validateattributes(is_persist, {'double', 'logical'}, {'nonempty', 'finite', 'scalar'}, '', 'is_persist');
if isnumeric(is_persist)
    is_persist = logical(is_persist);
end
validateattributes(threshold, {'double'}, {'nonempty', 'scalar', 'positive', 'finite', 'nonnan'}, '', 'threshold');

matlab.internal.sci.hdf5lib2('H5Pset_file_space_strategy',fcpl_id,strategy,is_persist,threshold);
