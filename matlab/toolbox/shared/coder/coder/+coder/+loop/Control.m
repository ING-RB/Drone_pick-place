classdef Control < coder.internal.loop.transforms.LoopTransform
%coder.loop.Control Loop optimization control object
%
%   Use this object to optimize for loops in the generated code.
%
%   coder.loop.Control properties:
%       transformSchedule - Loop transform specified as a coder.loop.Control object. This property further contains 
%                           its own transformSchedule property. 
%                           You can use the following methods to add more transforms to your top-level object. The subsequent 
%                           transforms are stored in the transformSchedule properties in a recursive manner.
%
%   coder.loop.Control methods:
%       apply                   - Apply the loop transformations contained in the loop control object to the for 
%                                 loop nest that immediately follows the apply call.
%       interchange             - Add a transform that interchanges a pair of nested for loops. 
%       parallelize             - Add a transform that parallelizes a for loop.
%       reverse                 - Add a transform that reverses the execution order of a for loop.
%       tile                    - Add a transform that tiles a for loop with an outer loop. 
%                                 You can specify the outer loop index name and increment step size.
%       unrollAndJam            - Add an unroll and jam transform to a for loop.
%       vectorize               - Add a transform that vectorizes a for loop. 
%
%   Example:
%       t = coder.loop.Control;
%       t = t.parallelize('i');
%

%#codegen
%   Copyright 2021-2022 The MathWorks, Inc.
    methods
        function obj = Control(val)
            if nargin == 0
                val = coder.internal.loop.transforms.EmptyTransform;
            end
            obj = obj@coder.internal.loop.transforms.LoopTransform(val);
        end
        
        function obj = reverse(self, varargin)
            coder.internal.preserveFormalOutputs;
            if coder.target('MATLAB') && nargout == 0
                return;
            end
            rev = coder.internal.loop.transforms.Reverse(self.transformSchedule, varargin{:});
            obj =  coder.loop.Control(rev);
        end
        
        function obj = interchange(self, varargin)
            coder.internal.preserveFormalOutputs;
            if coder.target('MATLAB') && nargout == 0
                return;
            end
            loopInterchange = coder.internal.loop.transforms.Interchange(self.transformSchedule, varargin{:});
            obj = coder.loop.Control(loopInterchange);
        end
        
        function obj = tile(self, varargin)
            coder.internal.preserveFormalOutputs;
            if coder.target('MATLAB') && nargout == 0
                return;
            end
            loopTile = coder.internal.loop.transforms.Tile(self.transformSchedule, varargin{:});
            obj =  coder.loop.Control(loopTile);
        end
        
        function obj = parallelize(self, varargin)
            coder.internal.preserveFormalOutputs;
            if coder.target('MATLAB') && nargout == 0
                return;
            end
            parallel = coder.internal.loop.transforms.Parallelize(self.transformSchedule, varargin{:});
            obj =  coder.loop.Control(parallel);
        end
        
        function obj = vectorize(self, varargin)
            coder.internal.preserveFormalOutputs;
            if coder.target('MATLAB') && nargout == 0
                return;
            end
            vector = coder.internal.loop.transforms.Vectorize(self.transformSchedule, varargin{:});
            obj =  coder.loop.Control(vector);
        end
        
        function obj = unrollAndJam(self, varargin)
            coder.internal.preserveFormalOutputs;
            if coder.target('MATLAB') && nargout == 0
                return;
            end
            unrollandjam = coder.internal.loop.transforms.UnrollAndJam(self.transformSchedule, varargin{:});
            obj =  coder.loop.Control(unrollandjam);
        end
        
        function out = apply(self)
            coder.internal.preserveFormalOutputs;
            if coder.target('MATLAB') && nargout == 0
                return;
            end
            out = self;
        end
    end
 end
