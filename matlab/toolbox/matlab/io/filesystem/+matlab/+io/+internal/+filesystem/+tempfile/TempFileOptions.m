classdef TempFileOptions

    properties
        OriginalName(1,1) string = missing;
        WebOptions = missing;
        Password(1,1) string = missing;
        OverrideExtension(1,1) string = missing;
    end

    methods

        function obj = TempFileOptions(args)
            arguments
                args.OriginalName(1,1) string;
                args.Password(1,1) string;
                args.WebOptions(1,1) weboptions;
                args.OverrideExtension(1,1) string;
            end
            for prop = string(fieldnames(args))'
                obj.(prop) = args.(prop);
            end
        end

        function tf = hasPassword(obj)
            tf = ~ismissing(obj.Password);
        end

        function tf = hasWebOptions(obj)
            tf = ~ismissing(obj.WebOptions);
        end

        function tf = hasOverrideExtension(obj)
            tf = ~ismissing(obj.OverrideExtension);
        end

        function tf = hasOriginalName(obj)
            tf = ~ismissing(obj.OriginalName);
        end
    end

    methods (Static)
        function obj = fromArgsStruct(st)
            arguments
                st(1,1) struct;
            end
            args = {};
            for prop = string(fieldnames(st))'
                args = [args,{prop,st.(prop)}]; %#ok<AGROW>
            end
            obj = matlab.io.internal.filesystem.tempfile.TempFileOptions(args{:});
        end
    end
end
%   Copyright 2024 The MathWorks, Inc.
