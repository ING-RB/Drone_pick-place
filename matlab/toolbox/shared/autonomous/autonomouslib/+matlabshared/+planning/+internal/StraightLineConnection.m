classdef StraightLineConnection < matlab.mixin.Copyable & matlabshared.planning.internal.EnforceScalarHandle
    %This class is for internal use only. It may be removed in the future.
    
    %StraightLineConnection Internal Straight-Line connection object
    %   StraightLineConnection is an internal class representing a
    %   Straight-Line connection.
    %
    %   obj = matlabshared.planning.internal.StraightLineConnection creates a
    %   Straight-Line connection object.
    %
    %   matlabshared.planning.internal.StraightLineConnection methods:
    %   connectInternal     - Connect start and goal poses using Straight-Line
    %                         connection.
    %
    %   See also matlabshared.planning.internal.ReedsSheppConnection,
    %   matlabshared.planning.internal.DubinsConnection.
    
    % Copyright 2018 The MathWorks, Inc.
    
    methods (Static, Access = {?matlabshared.planning.internal.StraightLinePathSegment,...
            ?matlab.unittest.TestCase, ?matlabshared.planning.internal.StraightLineConnection})
        
        function [lengths, directions] = connectInternal(startPose, goalPose)
            %connectInternal Connect a start and goal using Straight-Line
            %   connection.
            
            matlabshared.planning.internal.validation.connectInternalInputValidation(...
                startPose, goalPose);
            
            % Compute pairwise distances between given poses.
            lengths = matlabshared.planning.internal.pdist(startPose(:,1:2), goalPose(:,1:2))';
            
            % Compute direction           
            directions = ones(1,max(size(startPose,1), size(goalPose,1)));
        end
    end
end