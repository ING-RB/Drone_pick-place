function numberOptional = CountNumberOfOptionalInputs(inputArgs)
    arguments(Input)
        inputArgs (1,:) matlab.engine.internal.codegen.ArgumentTpl
    end
    arguments(Output)
        numberOptional (1,1) int32
    end
    numberOptional = 0;
    for arg = inputArgs
        if (arg.Presence == matlab.internal.metadata.ArgumentPresence.optional)
            numberOptional = numberOptional + 1;
        end
    end
end