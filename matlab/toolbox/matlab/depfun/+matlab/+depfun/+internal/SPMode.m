classdef SPMode
    %   Copyright 2021 The MathWorks, Inc.

    % List of valid modes for support package detection/inclusion
    enumeration
        NONE, AUTODETECT, MANUAL
    end

    methods(Static)
        function [spkgData,spkgMode] = validateSupportPackageInputs(inputs)

            spkgData = {};
            if isempty(inputs)
                spkgMode = matlab.depfun.internal.SPMode.AUTODETECT;
                return
            end

            validateattributes(inputs,{'char','string','cell'},{}, ...
                '','Support Package List')

            if ischar(inputs) || isstring(inputs)
                validateattributes(inputs,{'char','string'}, ...
                    {'scalartext'},'','Support Package List')
            else
                validateattributes(inputs,{'cell'}, ...
                    {'vector'},'','Support Package List')
            end
            inputs = cellstr(inputs);
            % Everything should be a cellstr by now

            N = numel(inputs);
            hasNone = any(strcmpi(inputs,char(matlab.depfun.internal.SPMode.NONE)));
            hasAutoDetect = any(strcmpi(inputs,char(matlab.depfun.internal.SPMode.AUTODETECT)));

            if N > 1
                if hasAutoDetect
                    error(message('MATLAB:depfun:req:SupportPackageModeOnlyOne', ...
                        lower(char(matlab.depfun.internal.SPMode.AUTODETECT))))
                end

                if hasNone
                    error(message('MATLAB:depfun:req:SupportPackageModeOnlyOne', ...
                        lower(char(matlab.depfun.internal.SPMode.NONE))))
                end
            end

            if hasAutoDetect
                assert(N==1) % being careful
                % spkgData will be determined downstream
                spkgMode = matlab.depfun.internal.SPMode.AUTODETECT;
                return
            end

            if hasNone
                assert(N==1) % being careful
                spkgMode = matlab.depfun.internal.SPMode.NONE;
                return
            end

            % Manual territory
            assert(~(hasAutoDetect || hasNone)) % being careful

            % go through the whole list and report all unknowns
            spkgMode = matlab.depfun.internal.SPMode.MANUAL;
            deployableSupportPkgs = matlab.depfun.internal.DeployableSupportPackages;
            unknownSP = {};
            spkgData = cell(N,1);
            for n = 1:N
                sp = deployableSupportPkgs.getSupportPackage(inputs{n});
                if isempty(sp)
                    unknownSP{end+1} = inputs{n}; %#ok<AGROW>
                else
                    spkgData{n} = sp;
                end
            end
            if ~isempty(unknownSP)
                error(message('MATLAB:depfun:req:UnknownSupportPackages', ...
                    strjoin(unknownSP,'\n'), ...
                    lower(char(matlab.depfun.internal.SPMode.AUTODETECT)), ...
                    lower(char(matlab.depfun.internal.SPMode.NONE))))
            end
        end
    end
end