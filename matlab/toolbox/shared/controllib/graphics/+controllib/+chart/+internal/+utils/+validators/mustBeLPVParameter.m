function mustBeLPVParameter(p,t,optionalInput)
    arguments
        p
        t (:,1) double {controllib.chart.internal.utils.validators.mustBeTimeVector(t)}
        optionalInput.ErrorMsg message = message.empty
    end
    if ~isa(p,'function_handle')
        ns = numel(t);
        sp = size(p);
        if ns<2
            % Do not support opaque step(sys,Tf,p)
            if isempty(optionalInput.ErrorMsg)
                error(message('Control:analysis:rfinputs24'))
            else
                error(optionalInput.ErrorMsg)
            end
        elseif ~(isnumeric(p) && ismatrix(p) && isreal(p) && allfinite(p) && any(sp==ns))
            if isempty(optionalInput.ErrorMsg)
                error(message('Control:analysis:rfinputs23'))
            else
                error(optionalInput.ErrorMsg)
            end
        end
    end
end