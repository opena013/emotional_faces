% Takes a model (a function which takes params, observations, and actions
% as parameters (in that order), and returns a struct that has 
% `log_likelihood` as a member), and returns a function that takes only
% parameters of the model as the argument, and returns the negative 
% loglikelihood. In other words, makes the model an easier function to
% optimize on. 
function [model_fn] = fit_to(model, actions, observations)
    function [ll] = fit_model(params)
        out = model(params, observations, actions);
        ll = -out.log_likelihood;
    end

    model_fn = @fit_model;
end