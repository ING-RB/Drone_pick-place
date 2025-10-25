function [isDefaultB, isDefaultT, B_x,B_y,B_z,T_x,T_y,T_z,numBlocksPerSM,name] = ...
    internalKernelHelper(varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc.
%#codegen

% =============================================================================================
% DO NOT CALL THIS FUNCTION FROM MATLAB CODE! This function is only to be called internally by
% EML inference.
% =============================================================================================
%
% This helper function is used to parse information supplied to a `coder.gpu.kernel` pragma call
% to make it easier to process the pragma builtin in EML inference. Validation of inputs is also
% performed here. Inputs are simply those forwarded from the pragma call.
%
% Meaning of the outputs:
%   isDefaultB (const bool): Should loop nest lowering use default launch params for
%   blocks per grid?
%
%   isDefaultT (const bool): Should loop nest lowering use default launch params for
%   threads per block?
%
%   B_x, B_y, B_z (uint32): The dim3 value representing the grid size (in blocks). These do not
%   need to be const.
%
%   T_x, T_y, T_z (uint32): The dim3 value representing the block size (in threads). These do
%   not need to be const.
%
%   numBlocksPerSM (const uint32): The minimum number of blocks per SM.
%
%   name: (const string): The name to be given to the kernel.
%
% Ideally, this should be placed under the `coder.gpu.internal` namespace. However, doing so
% requires updating `plc_libfcn_map.m`.

    coder.allowpcode('plain');
    coder.inline('always');
    coder.internal.prefer_const(varargin);
    narginchk(0,4);

    B_x = uint32(0);
    B_y = uint32(1);
    B_z = uint32(1);
    T_x = uint32(0);
    T_y = uint32(1);
    T_z = uint32(1);
    numBlocksPerSM = uint32(1);
    name = coder.internal.stringConst('');
    isDefaultB = true;
    isDefaultT = true;

    if nargin >= 1
        % If grid dims is specified, then so must be block dims.
        narginchk(2,4);
        B = varargin{1};
        T = varargin{2};

        coder.internal.assert(isnumeric(B) && isnumeric(T), 'gpucoder:common:KernelPragmaInvalidDimType');
        validSizeB = coder.internal.isConstTrue(isscalar(B) || numel(B) == 3);
        validSizeT = coder.internal.isConstTrue(isscalar(T) || numel(T) == 3);
        coder.internal.assert(validSizeB && validSizeT, 'gpucoder:common:KernelPragmaInvalidDimSize');

        isDefaultB = coder.internal.isConstTrue(isscalar(B) && B == -1);
        isDefaultT = coder.internal.isConstTrue(isscalar(T) && T == -1);
        if ~isDefaultB
            B_x = uint32(B(1));
            if numel(B) == 3
                B_y = uint32(B(2));
                B_z = uint32(B(3));
            end
        end
        if ~isDefaultT
            T_x = uint32(T(1));
            if numel(T) == 3
                T_y = uint32(T(2));
                T_z = uint32(T(3));
            end
        end
    end

    if nargin >= 3
        % The 3rd arg can either specify the min blocks per SM or the name. If the arg is a
        % char/string, assume it specifies the name. Otherwise, assume it specifies min blocks per
        % SM.
        %
        % Allowing the 3rd arg to specify the name is undocumented and is only supported for
        % backward compatibility. See g3166068.
        arg3 = varargin{3};
        if ischar(arg3) || isstring(arg3)
            name = coder.internal.stringConst(arg3);
            % This should be the last arg
            narginchk(3,3);
        else
            % Arg specifies min blocks per SM
            if coder.const(arg3) ~= -1
                coder.internal.assert(isnumeric(arg3) && isscalar(arg3) && coder.internal.isConst(arg3), ...
                                      'gpucoder:common:KernelPragmaInvalidMinBlocksPerSM');
                numBlocksPerSM = coder.const(uint32(arg3));
            end
            if nargin == 4
                name = coder.internal.stringConst(varargin{4});
            end
        end
    end
end

% LocalWords:  plc libfcn
