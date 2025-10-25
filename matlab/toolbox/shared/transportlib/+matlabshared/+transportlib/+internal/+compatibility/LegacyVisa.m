classdef (Abstract, Hidden) LegacyVisa < matlabshared.transportlib.internal.compatibility.LegacyBase & ...
                                         matlabshared.transportlib.internal.compatibility.LegacyBinaryMixin & ...
                                         matlabshared.transportlib.internal.compatibility.LegacyASCIIMixin & ...
                                         matlabshared.transportlib.internal.compatibility.LegacyBinblockMixin & ...
                                         matlabshared.transportlib.internal.compatibility.LegacyQueryMixin
    %LEGACYVISA Specific implementation of legacy visa support. The
    %visalib.Resource class must inherit from it in order to support legacy
    %operations.
    %
    %    This undocumented class may be removed in a future release.

    % Copyright 2021 The MathWorks, Inc.

    %#codegen
    properties (Hidden)
        EOSMode = 'read&write'
    end

    properties (Hidden, SetAccess = private, Dependent)
        EOSCharCode 
        RsrcName
    end

    %% Getters / Setters
    methods
        function value = get.EOSCharCode(obj)
            % Refers to visalib.Resource's "Terminator"
            if iscell(obj.Terminator)
                value = obj.Terminator{1};
                % codegen does not support cellfun; replace with for-loop, as needed.
                types = string(cellfun(@class, obj.Terminator, 'UniformOutput', false));
                mismatch = false;
                if types(1) ~= types(2)
                    mismatch = true;
                elseif obj.Terminator{1} ~= obj.Terminator{2}
                    mismatch = true;
                end

                if mismatch
                    obj.sendWarning('transportlib:legacy:EOSCharCodeMismatch', ...
                                    obj.Terminator{1}, ...
                                    obj.Terminator{2});
                end
            else
                value = obj.Terminator;
            end
        end

        function value = get.RsrcName(obj)
            % Refers to visalib.Resource's "ResourceName"
            value = convertStringsToChars(obj.ResourceName);
        end
    end    

    methods (Sealed, Hidden)
        function clrdevice(obj)
            % For VISA, this should also call viClear
            flush(obj);
        end
    end

    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyVisa
            coder.allowpcode('plain');
        end
    end
end