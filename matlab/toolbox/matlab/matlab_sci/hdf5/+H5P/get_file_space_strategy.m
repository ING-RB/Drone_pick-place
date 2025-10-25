function [strategy,is_persist,threshold] = get_file_space_strategy(fcpl_id)
%H5P.get_file_space_strategy  Gets the file space handling information.
%   [strategy,is_persist,threshold] = H5P.get_file_space_strategy(fcpl_id)
%   retrieves the file space handling strategy (strategy), persisting
%   free-space condition (is_persist) and threshold value (threshold) for
%   file creation property list identifier fcpl_id.
%   The library default values returned when H5P.set_file_space_strategy has
%   not been called are:
%
%       strategy:  'H5F_FSPACE_STRATEGY_FSM_AGGR'
%       is_persist:   FALSE (0)
%       threshold: 1
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
%         H5P.close(fcplID);
%         H5P.close(faplID);
%
%   See also H5P, H5P.set_file_space_strategy

%   Copyright 2024 The MathWorks, Inc.

validateattributes(fcpl_id, {'H5ML.id'}, {'nonempty', 'scalar'});
[strategy,is_persist,threshold] = matlab.internal.sci.hdf5lib2('H5Pget_file_space_strategy',fcpl_id);
