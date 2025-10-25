classdef DataHolder
    %#codegen
    properties
        data
    end
    properties (Access = private)
        varsizeDims
    end
    methods
        function obj = DataHolder(data, varsizeDims)
            arguments
                data
                varsizeDims {mustBeNumericOrLogical, mustBeRow, mustBeNonscalar}
            end
            coder.internal.prefer_const(varsizeDims);
            obj.data = data;
            obj.varsizeDims = varsizeDims;
        end
    end
    methods (Static)
        function props = matlabCodegenNontunableProperties(~)
            props = {'varsizeDims'};
        end
        function optOut = matlabCodegenLowerToStruct(~)
            % Deep Learning Coder wants efficient IR, even when generating
            % C++. CGIR optimizes less on classes, so here we opt-out.
            % We want this class to be exploded in the generated code.
            % See also: dlnetwork
            optOut = true;
        end
    end
end
function mustBeRow(in)
    coder.internal.assert(isrow(in), 'MATLAB:validators:mustBeRow');
end
function mustBeNonscalar(in)
    coder.internal.assert(~isscalar(in), 'Coder:builtins:Explicit', 'Dimensions vector must be nonscalar');
end