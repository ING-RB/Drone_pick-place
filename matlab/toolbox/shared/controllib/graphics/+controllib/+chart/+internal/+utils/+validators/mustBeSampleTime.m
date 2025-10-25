function mustBeSampleTime(time,optionalInput)
    arguments
        time (1,1) double
        optionalInput.ErrorMsg message = message.empty
    end
    try
        if time ~= 1
            mustBeNonnegative(time);
        end
    catch
        if isempty(optionalInput.ErrorMsg)
            error(message('Controllib:plots:mustBeSampleTime'))
        else
            error(optionalInput.ErrorMsg)
        end
    end
end