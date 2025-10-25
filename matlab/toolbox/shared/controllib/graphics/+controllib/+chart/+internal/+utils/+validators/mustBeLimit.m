function mustBeLimit(value,type,optionalInput)
    arguments
        value
        type (1,1) string {mustBeMember(type,["numeric","duration","datetime"])} = "numeric"
        optionalInput.ErrorMsg message {mustBeScalarOrEmpty} = message.empty
    end
    try
        controllib.chart.internal.utils.validators.mustBeSize(value,[1 2]);
        switch type
            case "numeric"
                mustBeNumeric(value);
                if ~any(isnan(value))
                    assert(value(2)>value(1));
                end
            case "duration"
                mustBeA(value,"duration");
                if ~any(isnan(value))
                    assert(value(2)>value(1));
                end
            case "datetime"
                mustBeA(value,"datetime");
                if ~any(isnat(value))
                    assert(value(2)>value(1));
                end
        end
    catch
        if isempty(optionalInput.ErrorMsg)
            error(message('Controllib:plots:mustBeLimit',type));
        else
            error(optionalInput.ErrorMsg);
        end
    end
end