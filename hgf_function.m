%%% HGF pipeline main function for Faces Task 2022
function [x, table] = hgf_function(str_run, file, rt_model, p_or_r, cb, experiment_mode)

% make sure both logrt inputs and stim inputs are arrays
if strcmp(str_run,'2')
    test = '-retest';
else
    test = [];
end

    if rt_model
        [rt_trials, table] = get_rts(file, p_or_r, experiment_mode);
        logrts = prep_data_rthgf(table2array(rt_trials(:,'response_times')));
        stim_inputs = rt_trials.observed;
        
        x = tapas_fitModel(logrts, stim_inputs, ...
                                 'tapas_hgf_binary_config',...
                                 'tapas_logrt_linear_binary_config',...
                                 'tapas_quasinewton_optim_config'); % or optim_config
    else
        [responses, table] = get_responses(file, p_or_r,experiment_mode);
        
        x = tapas_fitModel_actprob(responses.response, responses.observed,...
                            'tapas_hgf_binary_config', ...
                            'tapas_bayes_optimal_binary_config', ...
                            'tapas_quasinewton_optim_config');
    
    end
end