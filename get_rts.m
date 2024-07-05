function [rts, clean_table] = get_rts(raw, p_or_r, experiment_mode)
% Read in raw participant data and extract rts for HGF

if (experiment_mode == "mturk") | (experiment_mode == "prolific")
    first_game_trial = min(find(ismember(raw.trial_type, 'MAIN'))) +3;
    clean_table = raw(first_game_trial:end, :);
    if (experiment_mode == "mturk") 
        second_half = min(find(ismember(clean_table.trial_type, 'MAIN2'))) + 3;
        clean_table(second_half:end,:).trial = clean_table(second_half:end,:).trial + 100;
    end
    % indicate event code for response or prediction
    if strcmp(p_or_r, 'r')
        ecode = 7;
    elseif strcmp(p_or_r, 'p')
        ecode = 12;
    end
    % put in 1 for stim_inputs being sad_high or angry_low; put 0 for when
    % they are sad_low or angry_high
    stim_inputs.stim_inputs = double(ismember(clean_table(clean_table.event_type == 5,'trial_type').trial_type, {'sad_high', 'angry_low'}));
    table = clean_table(clean_table.event_type == ecode,:);
elseif experiment_mode == "inperson"
    first_game_trial = 3;
    last_game_trial = find(raw.trial == 200);
    clean_table = raw(first_game_trial:last_game_trial-1, :);
    % indicate event code for response or prediction
    if strcmp(p_or_r, 'r')
        ecode = 8;
    elseif strcmp(p_or_r, 'p')
        ecode = 6;
    end
    stim_inputs.stim_inputs = double(ismember(clean_table(clean_table.event_code == 11 & strcmp(clean_table.result, 'start'),'trial_type').trial_type, {'sad_high', 'angry_low'}));
    table = clean_table(clean_table.event_code == ecode,:);
end

stim_inputs.trial = [0:199]';

missingtrials = setdiff(0:199, table.trial) + 1;
    
rts_char = table(:,{'trial', 'response_time'});
    

j = 1;
for i = 1:200
    rts(i,1) = i;
    rts(i,3) = stim_inputs.stim_inputs(i);
    if ismember(i, missingtrials)
        rts(i,2) = nan;
    else
        rts(i,2) = round(str2num(rts_char(j,'response_time').response_time{1}),4);
        j = j + 1;
    end
end 
    
rts = array2table(rts);
%rts.observed = struct2table(stim_inputs).stim_inputs;
rts.Properties.VariableNames = ["trial_number", "response_times", "observed"];
