% Generic grid search utility function.
% 
% Given a configuration (detailing parameters and their mins/maxes/step
% sizes) and a model, will perform a grid search and optimize for a
% minimizes negative log-likelihood.
% 
% Example `config`:
%
% CONFIG.SI = struct(         ...
%     'min', 0,               ...
%     'max', 100,             ...
%     'step', 2               ...
% );
% CONFIG.IP = struct(         ...
%     'min', 0,               ...
%     'max', 1.0,             ...
%     'step', 0.1             ...
% );
% CONFIG.omega = struct(      ...
%     'min', 0,               ...
%     'max', 1.0,             ...
%     'step', 0.1             ...
% );
%
% Parameters:
%   config:  struct with named fields denoting parameter names. The names
%            in the struct should match those that `fit_to_model` expects.
%       `param1`: struct with fields:
%           min:  minimum value for `param1`
%           max:  maximum value for `param1`
%           step: step-size for `param1`, definining the resolution of the
%                 grid search procedure.
%       `param2`: struct with fields:
%           min:  minimum value for `param2`
%           max:  maximum value for `param2`
%           step: step-size for `param2`, definining the resolution of the
%                 grid search procedure.
%   fit_to_model: Typically the output of a `fit_to` call. `fit_to` returns
%                 a model that uses provided observations and actions.
% 
% Return Values:
%   optim: The optimal set of parameter values with the given configuration
%          and model.
%   grid: A table containing all searched parameter combinations and
%         associated (negative) log-likelihoods. Useful for grid search
%         diagnostics and for generating heatmaps.
%
% Written by: Samuel Taylor, Laureate Institute for Brain Research (2022)

function [optim, grid] = grid_search(config, fit_to_model)
    % Spaces points out evenly in the format prescribed by `config`
    function [a] = lspace(l)
        a = linspace(l.min, l.max, ((l.max - l.min)/l.step) + 1);
    end

    vars = fields(config);
    bounds = cell(numel(vars), 1);
    
    for vari = 1:numel(vars)
        var = vars{vari};
        
        bounds{vari} = lspace(config.(var))';
    end
    
    combinations = cartesian_product(bounds{:});
    combinations = array2table(combinations, 'VariableNames', vars);
    
    best_LL = Inf;
    optim = NaN;
    
    grid = combinations;
    grid.log_likelihood = repelem(0, size(grid, 1))';
    
    wb = waitbar(0, 'Conducting grid search...');
    
    for ci = 1:size(combinations, 1)
        waitbar(ci / size(combinations, 1), wb);
        
        params = combinations(ci, :);
        LL = fit_to_model(params);
        
        grid.log_likelihood(ci) = LL;
        
        if LL < best_LL
            best_LL = LL;
            optim = table2struct(params);
        end
    end
    
    close(wb);
    
    optim.log_likelihood = best_LL;
end