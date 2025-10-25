classdef (Abstract) AutonomousBuildable < coder.ExternalDependency
%This class is for internal use only. It may be removed in the future.

%AUTONOMOUSBUILDABLE Base class for all shared_autonomous classes that support code generation

% Copyright 2018-2023 The MathWorks, Inc.

%#codegen

    methods (Static)
        
        function isSupported = isSupportedContext(~)
        %isSupportedContext Determine if external dependency supports this build context

            % Code generation is supported for both host and target
            % (portable) code generation.
            isSupported = true;
            
        end

        function updateBuildInfo(~,~)
            %updateBuildInfo Empty prototype
            %   Note that this empty function is needed, since all classes
            %   directly deriving from coder.ExternalDependency need to
            %   have updateBuildInfo defined. In practice, the actual
            %   implementation of updateBuildInfo in classes deriving from
            %   AutonomousBuildable are called, e.g.
            %   DubinsBuildable/updateBuildInfo.
            %   See g1427050 for more explanation.
        end
        
    end
    
    methods (Static, Access = protected)
        function addCommonHeaders(buildInfo)
            %addCommonHeaders Add include path for autonomous codegen APIs.
            
            includePath = fullfile(matlabroot, 'extern', 'include', 'shared_autonomous');
            buildInfo.addIncludePaths(includePath, 'Shared Autonomous Includes');
        end
        
        function updateBuildInfoForHostCodegen(buildInfo, buildConfig)
            %updateBuildInfoForHostCodegen Add build information for host codegen
            %   If generating code for the host, we can directly link against the
            %   shipping, host-specific libmwautonomouscodegen library.
            %   Since this library uses TBB for parallel execution, also
            %   package all dependent libraries.
            
            autonomousLibNoExt = 'libmwautonomouscodegen';
            
            % Link against the autonomouscodegen module.
            [linkLibPath,linkLibExt] = buildConfig.getStdLibInfo();
            
            % On Windows, don't use linkLibPath returned by getStdLibInfo because it
            % is the MATLAB sandbox lib directory and that is not where the lib of
            % the shipped product resides.
            if ispc
                libDir = coder.internal.importLibDir(buildConfig);
                linkLibPath = fullfile(matlabroot,'extern','lib',computer('arch'),libDir);
            end
            buildInfo.addLinkObjects([autonomousLibNoExt linkLibExt], linkLibPath, [], true, true);
            
            % Non-build dependencies. We need to also package all library
            % dependencies for libmwautonomouscodegen. This is important
            % for pack'n'go workflows.
            % All of our buildable autonomous functionality requires TBB
            % for parallel execution.
            arch      = computer('arch');
            binArch   = fullfile(matlabroot,'bin',arch);
            sysOSArch = fullfile(matlabroot,'sys','os',arch);
            
            % By default, don't include libstdc++ and assume that the TBB
            % libraries have no prefix
            libstdcppFull = {''};
            tbbLibsPrefix = '';
            
            % Include the executable shared library for shared autonomous
            % in the non-build files
            switch arch
                case 'glnxa64'
                    % Include libstdc++.so.6 on Linux, since we
                    % are shipping a MathWorks specific version.
                    libstdcppFull = {fullfile(sysOSArch, 'libstdc++.so.6')};
                    tbbLibsPrefix = 'lib';
                    
                case 'maci64'
                    tbbLibsPrefix = 'lib';
            end
            
            % Gather all TBB libraries. Use the architecture-specific
            % prefix. Use the tbb* wildcard here to capture the library
            % extension and possible versioning, e.g. libtbb.so.12 on Linux.
            tbbLibsInfo = dir(fullfile(binArch, strcat(tbbLibsPrefix, 'tbb*')));
            tbbLibsFullPath = fullfile({tbbLibsInfo.folder}, {tbbLibsInfo.name});
            
            % Get libmwautonomouscodegen library
            autLibInfo = dir(fullfile(binArch, strcat(autonomousLibNoExt, '*')));
            autLibFullPath = fullfile({autLibInfo.folder}, {autLibInfo.name});
            
            % Include all executable shared library in the non-build files
            nonBuildFiles = [libstdcppFull autLibFullPath tbbLibsFullPath];
            buildInfo.addNonBuildFiles(nonBuildFiles, '', '');
        end

        function [numStartPoses, numGoalPoses, maxNumPoses] = numPoses(startPose, goalPose)
        %numPoses Calculate the number of start and goal poses in the inputs
            numStartPoses = size(startPose,1);
            numGoalPoses = size(goalPose,1);
            maxNumPoses = max(numStartPoses, numGoalPoses);
        end

        function tbbPart = tbbAPIPart(varargin)
            %tbbAPIPart Retrieve TBB API string
            %   This string is used to indicate if certain headers or C-API
            %   functions are TBB-based or not TBB-based

            if coder.target('mex')
                % If we are generating MEX on the host, use the TBB API
                tbbPart = '_tbb';
            else
                % Otherwise, call the non-TBB API
                tbbPart = '';
            end

        end
        
    end
end
