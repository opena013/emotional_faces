function [r_table, clean_table, stims] = get_responses(raw, p_or_r,experiment_mode)
if experiment_mode == "mturk" | experiment_mode == "prolific"
    first_game_trial = min(find(ismember(raw.trial_type, 'MAIN'))) +3;
    clean_table = raw(first_game_trial:end, :);
    if experiment_mode == "mturk"
        second_half = min(find(ismember(clean_table.trial_type, 'MAIN2'))) + 3;
        clean_table(second_half:end,:).trial = clean_table(second_half:end,:).trial + 100;
    end

    if strcmp(p_or_r, 'p')
        ecode = 12;
    elseif strcmp(p_or_r, 'r')
        ecode = 7;
    end
    stims = clean_table(clean_table.event_type == 5,{'trial', 'trial_type'});
    table = clean_table(clean_table.event_type == ecode,:);

elseif experiment_mode=="inperson"
    first_game_trial = 3;
    last_game_trial = find(raw.trial == 200);
    clean_table = raw(first_game_trial:last_game_trial-1, :);
    % indicate event code for response or prediction
    if strcmp(p_or_r, 'r')
        ecode = 8;
    elseif strcmp(p_or_r, 'p')
        ecode = 6;
    end
%    stim_inputs.stim_inputs = double(ismember(clean_table(clean_table.event_code == 11 & strcmp(clean_table.result, 'start'),'trial_type').trial_type, {'sad_high', 'angry_low'}));
%    table = clean_table(clean_table.event_code == ecode,:);
    stims = clean_table(clean_table.event_code == 11 & strcmp(clean_table.result, 'start'),{'trial', 'trial_type'});
    table = clean_table(clean_table.event_code == ecode,:);
    table.trial=table.trial_number;
end

missingtrials = setdiff(0:199, table.trial);

responses=[];
stim_inputs=[];
% Responses are based on a sad-high/angry-low contingency (as are stimulus inputs). 
% 1= they were consistent with this contingency, 0= they were consistent with
% sad-low/angry-high
% note that left response means participant thought face was angry, right
% means sad
j=0;
for i = 1:200
    if ~ismember(i-1, missingtrials)
        j=j+1;
        if strcmp(table(table.trial==i-1,:).response{1},"left")&&strcmp(extractAfter(stims.trial_type{j}, '_'), 'high')||...
                strcmp(table(table.trial==i-1,:).response{1},"right")&&strcmp(extractAfter(stims.trial_type{j}, '_'), 'low')
            responses = [responses 0];
        elseif strcmp(table(table.trial==i-1,:).response{1},"right")&&strcmp(extractAfter(stims.trial_type{j}, '_'), 'high')||...
                strcmp(table(table.trial==i-1,:).response{1},"left")&&strcmp(extractAfter(stims.trial_type{j}, '_'), 'low')
            responses = [responses 1];
        end
    else
        responses = [responses nan];
     %   stim_inputs = [stim_inputs nan];
    end
    stim_inputs = [stim_inputs double(ismember(stims.trial_type{i}, {'sad_high', 'angry_low'}))];
end     

r_table = array2table(horzcat([0:199]', responses', stim_inputs'));


r_table.Properties.VariableNames = ["trial_number", "response", "observed"];