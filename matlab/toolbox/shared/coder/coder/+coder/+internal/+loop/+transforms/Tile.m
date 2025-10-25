classdef Tile < coder.internal.loop.transforms.OneLoopTransform
%
% This is an internal class for code generation.
%

%#codegen
%   Copyright 2021-2023 The MathWorks, Inc.
    properties
       tileSize (1,1) {mustBePositive, mustBeInteger, coder.mustBeConst(tileSize, 'Coder:loopControl:NotConstantTileSize')} = 2;
       tiledLoopId {mustBeTextScalar, coder.mustBeConst(tiledLoopId, 'Coder:loopControl:NotConstantLoopIdToTransform')} = '_tiledLoopId';
    end

    methods (Access = ?coder.loop.Control)
        function obj = Tile(prevTransform, varargin)
            obj = obj@coder.internal.loop.transforms.OneLoopTransform(prevTransform, varargin{:});
            if nargin > 2
                obj.tileSize = varargin{2};
            else
                obj.tileSize = 2; % need this assignment for inference to 
                % succeed, otherwise we get a nontunable property mismatch 
                % error
            end
            if nargin > 3
                obj.tiledLoopId = char(varargin{3});
            else
                obj.tiledLoopId = '_tiledLoopId';
            end
        end
    end
    
    methods
        function [scheduleString, codeInsightToReport, outLoopIds] = validate(self, loopIds)
            [scheduleString, codeInsightToReport, loopIds] = validate@coder.internal.loop.transforms.OneLoopTransform(self, loopIds, 'tile');
            scheduleString = [scheduleString, num2str(self.tileSize), ','];
            self.validateTiledLoopID(loopIds);
            scheduleString = [scheduleString, self.tiledLoopId, ','];
            % Update loopIds to include the tiledLoopId provided by
            % the user so that 'next' loop pragmas in the chain treat
            % this loop ID as a valid loop ID to be referred to.
            % See: g2563468
            outLoopIds = {loopIds{:}, self.tiledLoopId};         
        end
    end

    methods(Access=private)
        function validateTiledLoopID(self, loopIds)
            if ~isempty(self.tiledLoopId) 
                % validate tiled loop ID not already present in the loop IDs
                tiledLoopIdfound = coder.internal.loop.transforms.LoopTransform.isLoopIdFound(self.tiledLoopId, loopIds);
                coder.internal.assert(tiledLoopIdfound == false, 'Coder:loopControl:TiledLoopIdConflict',...
                    self.tiledLoopId);
            end
        end
    end
 end
