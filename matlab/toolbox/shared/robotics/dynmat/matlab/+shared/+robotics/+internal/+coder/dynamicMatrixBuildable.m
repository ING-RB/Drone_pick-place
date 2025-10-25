classdef dynamicMatrixBuildable < coder.ExternalDependency
%This class is for internal use only. It may be removed in the future.

%dynamicMatrixBuildable Interface to dynamic matrix/array for codegen
%
%   This class is a collection of functions used for interfacing with the
%   a matrix or array which is dynamically allocated inside a C++ builtin
%   function.
%
%   The C++ code returns a pointer to an object storing a std::vector, with
%   functions for querying the pointer's size, copying contents to a
%   standard C-array, and cleaning up the pointer once this object goes out
%   of scope.
%
%       IMPORTANT: When reading back to MATLAB, the pointer stored by this
%       wrapper is treated as a simple linear array.
%
%
%   Example:
%       MATLAB:
%           ...
%           % Create container for dynamically allocated matrix
%           matWrapper = shared.robotics.internal.coder.dynamicMatrixBuildable([inf 3]); % Voxel center(s)
%
%           % The C++ function "foo" returns a wrapper around some dynamically allocated C++ object representing [inf 3] matrix
%           coder.ceval('foo', ..., coder.ref(matWrapper.Ptr));
%
%           % Copy data back to matlab
%           mat = matWrapper.getData();
%
%           % C++ object will get cleaned up automatically when matWrapper goes out of scope
%
%       C++:
%           void foo(..., void** voidWrapper)
%           {
%               // Generate a dynamically allocated resource
%               auto* data = new std::vector<std::array<double,3>>();
%
%               // Allocate/define populate the data
%               ...
%
%               // Wrap the resource in the DynamicMatrix marshaller
%               auto* dynamicMat = new nav::DynamicMatrix<std::vector<std::array<double, 3>>, 2>(std::move(nav::raw2unique(ctrs)), { ctrs->size(), 3});
%
%               // Generate a new DynamicMatrixVoidWrapperBase and point the void** to it
%               nav::createWrapper<double>(dynamicMat,*voidWrapper);
%           }
%
%   See also nav.algs.internal.coder.occupancyMap3DBuildable

% Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    methods (Static)
        function name = getDescriptiveName(~)
        %getDescriptiveName Get name for external dependency
            name = 'dynamicMatrixBuildable';
        end

        function updateBuildInfo(buildInfo, buildConfig) %#ok<INUSD>
        %updateBuildInfo Add headers, libraries, and sources to the build info

            shared.robotics.internal.coder.dynamicMatrixBuildable.addCommonHeaders(buildInfo);

            % Always use full sources for code generation
            buildInfo.addSourcePaths({fullfile(matlabroot,'toolbox', ...
                'shared','robotics','dynmat','builtins','libsrc','dynmatcodegen')});
            buildInfo.addSourceFiles('dynamicmatrix_api.cpp');
        end

        function isSupported = isSupportedContext(~)
        %isSupportedContext Determine if external dependency supports this build context

        % Code generation is supported for both host and target
        % (portable) code generation.
            isSupported = true;
        end
    end

    methods (Static, Access = protected)
        function addCommonHeaders(buildInfo)
        %addCommonHeaders Add include path for codegen APIs.

            includePath = fullfile(matlabroot, 'extern', 'include', 'nav');
            buildInfo.addIncludePaths(includePath, 'Navigation Toolbox Includes');
        end
    end

    properties
        %Ptr Pointer to C++ object storing the allocated pointer
        Ptr

        %RefType A scalar used to indicate the expected type of the data stored in C++
        RefType

        %SizeInfo The number of dimensions must be fixed at compile time
        SizeInfo
    end

    methods
        function obj = dynamicMatrixBuildable(sizeInfo,referenceType)
        %dynamicMatrixBuildable Constructor
            narginchk(1,2);
            validateattributes(sizeInfo,{'numeric'},{'positive','nonnan'},'dynamicMatrixBuildable','sizeInfo');
            coder.internal.assert(numel(sizeInfo) > 1, 'nav:navalgs:dynamicmatrix:AtLeast2Dimensions');
            
            obj.SizeInfo = sizeInfo;
            if nargin == 1
                referenceType = 0; % double
            end
            obj.Ptr = coder.opaquePtr('void',coder.internal.null);

            obj.RefType = referenceType;
        end

        function delete(obj)
        %delete Calls destructor on C++ pointer
            coder.cinclude('dynamicmatrix_api.hpp')

            % Delete opaque matrix and free memory
            coder.ceval('dynamicmatrixcodegen_destruct',obj.Ptr);
        end

        function sz = getSize(obj)
        %getSize Creates the size matrix
            coder.cinclude('dynamicmatrix_api.hpp')

            % Allocate size matrix
            numDim = coder.internal.ndims(obj.SizeInfo);
            sz = ones(1,numDim,'uint64');
            nDim = uint64(0);
            nDim = coder.ceval('dynamicmatrixcodegen_getNumDimensions',obj.Ptr);
            assert(nDim == numDim || ... % General case for N-dim matrices
                   (numDim == 2 && any(obj.SizeInfo == [1 1])), ... % Case for vectors
                   'nav:navalgs:dynamicmatrix:NumDimensionMismatch');

            % Retrieve matrix size
            coder.ceval('dynamicmatrixcodegen_getMATLABSize',obj.Ptr,coder.ref(sz));
        end

        function mat = getData(obj)
        %getData Copy the data from the C++ object to a matrix
            coder.cinclude('dynamicmatrix_api.hpp')

            % Retrieve size
            sz = obj.getSize();

            % Make a dear promise to coder on memory allocated
            if numel(obj.SizeInfo) == 2 && coder.internal.isConstTrue(obj.SizeInfo(1) == 1)
                mat = zeros([1 int32(sz)],'like',obj.RefType);
            else
                mat = zeros([int32(sz) 1],'like',obj.RefType);
            end

            % Extract matrix
            switch class(obj.RefType)
              case 'double'
                coder.ceval('dynamicmatrixcodegen_retrieve_REAL64',obj.Ptr,coder.ref(mat));
              case 'single'
                coder.ceval('dynamicmatrixcodegen_retrieve_REAL32',obj.Ptr,coder.ref(mat));
              case 'uint64'
                coder.ceval('dynamicmatrixcodegen_retrieve_UINT64',obj.Ptr,coder.ref(mat));
              case 'uint32'
                coder.ceval('dynamicmatrixcodegen_retrieve_UINT32',obj.Ptr,coder.ref(mat));
              case 'int64'
                coder.ceval('dynamicmatrixcodegen_retrieve_INT64',obj.Ptr,coder.ref(mat));
              case 'int32'
                coder.ceval('dynamicmatrixcodegen_retrieve_INT32',obj.Ptr,coder.ref(mat));
              case 'logical'
                coder.ceval('dynamicmatrixcodegen_retrieve_BOOLEAN',obj.Ptr,coder.ref(mat));
            end
        end
    end

    methods (Static, Hidden)
        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenSoftNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'SizeInfo','RefType'};
        end
    end
end
