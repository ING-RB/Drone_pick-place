function mustBeTimeVector(t,optionalInput)
    arguments
        t (:,1) double
        optionalInput.ErrorMsg message = message.empty
    end
    if ~isempty(t)
        if isscalar(t)
            % Final time
            if ~(isnumeric(t) && isreal(t))
                if isempty(optionalInput.ErrorMsg)
                    error(message('Control:analysis:rfinputs13'))
                else
                    error(optionalInput.ErrorMsg)
                end
            end
            if t<=0 || ~isfinite(t)
                if isempty(optionalInput.ErrorMsg)
                    error(message('Control:analysis:rfinputs13'))
                else
                    error(optionalInput.ErrorMsg)
                end
            end            
        elseif isvector(t)
            % Time vector specified
            if ~(isnumeric(t) && isreal(t))
                if isempty(optionalInput.ErrorMsg)
                    error(message('Control:analysis:rfinputs14'))
                else
                    error(optionalInput.ErrorMsg)
                end
            end
            dt = t(2)-t(1);
            if ~(allfinite(t) && all(diff(t)>0) && all(abs(diff(t)-dt)<0.01*dt))
                if isempty(optionalInput.ErrorMsg)
                    error(message('Control:analysis:rfinputs14'))
                else
                    error(optionalInput.ErrorMsg)
                end
            end
        end
    end
end