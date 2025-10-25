function mustBeFrequencySpec(w,optionalInput)
    arguments
        w (:,1)
        optionalInput.IncludeNegative (1,1) logical = true
        optionalInput.ErrorMsg message = message.empty
    end
    if ~isempty(w)
        if iscell(w)
            % W = {WMIN , WMAX}
            if ~(numel(w)==2 && isscalar(w{1}) && isscalar(w{2}))
                if isempty(optionalInput.ErrorMsg)
                    error(message('Control:analysis:rfinputs11'))
                else
                    error(optionalInput.ErrorMsg)
                end
            end
            wmin = w{1}(1);
            wmax = w{2}(1);
            if ~(isnumeric(wmin) && isreal(wmin) && isnumeric(wmax) && isreal(wmax) && wmax>wmin && wmin>=0)
                if isempty(optionalInput.ErrorMsg)
                    error(message('Control:analysis:rfinputs11'))
                else
                    error(optionalInput.ErrorMsg)
                end
            end
        else
            if ~(isnumeric(w) && isreal(w) && isvector(w) && ~any(isnan(w)))
                if isempty(optionalInput.ErrorMsg)error(message('Control:analysis:rfinputs22'))
                else
                    error(optionalInput.ErrorMsg)
                end
            elseif ~optionalInput.IncludeNegative && any(w<0)
                if isempty(optionalInput.ErrorMsg)
                    error(message('Control:analysis:rfinputs12'))
                else
                    error(optionalInput.ErrorMsg)
                end
            end
        end
    end
end