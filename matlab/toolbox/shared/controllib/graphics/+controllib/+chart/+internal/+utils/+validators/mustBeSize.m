function mustBeSize(value,desiredSize,optionalInput)
    arguments
        value
        desiredSize double
        optionalInput.ErrorMsg message = message.empty
    end
    if isscalar(desiredSize)
        desiredSize = [desiredSize,1]; %Assume column vectors
    end
    if ~isequal(size(value),desiredSize)
        if isempty(optionalInput.ErrorMsg)
            error(message('Controllib:plots:mustBeSize',mat2str(desiredSize)));
        else
            error(optionalInput.ErrorMsg);
        end
    end
end