function [r_table, clean_table] = get_responses(file, p_or_r)
% Read in raw participant data and extract responses for binary HGF
raw = file;

first_game_trial = min(find(ismember(raw.trial_type, 'MAIN'))) +3;
    
clean_table = raw(first_game_trial:end, :);
    
second_half = min(find(ismember(clean_table.trial_type, 'MAIN2'))) + 3;
clean_table(second_half:end,:).trial = clean_table(second_half:end,:).trial + 100;

if strcmp(p_or_r, 'p')
    ecode = 12;
elseif strcmp(p_or_r, 'r')
    ecode = 7;
end

table = clean_table(clean_table.event_type == ecode,:);
missingtrials = setdiff(0:199, table.trial);

responses=[];
observed=[];
% Responses are based on a sad-high/angry-low contingency (as are stimulus inputs). 
% 1= they were consistent with this contingency, 0= they were consistent with
% sad-low/angry-high
j=0;
for i = 1:200
    if ~ismember(i-1, missingtrials)
        j=j+1;
        % What the participant thought the trial type was
        if strcmp(table(table.trial==i-1,:).response{1},"left")&&strcmp(extractAfter(table.trial_type{j}, '_'), 'high')||...
                strcmp(table(table.trial==i-1,:).response{1},"right")&&strcmp(extractAfter(table.trial_type{j}, '_'), 'low')
            % hightone/angry or lowtone sad
            responses = [responses 0];
        elseif strcmp(table(table.trial==i-1,:).response{1},"right")&&strcmp(extractAfter(table.trial_type{j}, '_'), 'high')||...
                strcmp(table(table.trial==i-1,:).response{1},"left")&&strcmp(extractAfter(table.trial_type{j}, '_'), 'low')
            % hightone/sad or lowtone angry
            responses = [responses 1];
        end
        % What the trial type really was
        if strcmp(table.trial_type{j}, 'sad_high')||...
                strcmp(table.trial_type{j}, 'angry_low')
            observed= [observed 1];
        elseif strcmp(table.trial_type{j}, 'sad_low')||...
                strcmp(table.trial_type{j}, 'angry_high')
            observed= [observed 0];
        end
    else
        responses = [responses nan];
        observed = [observed nan];
    end
end     

r_table = array2table(horzcat([0:199]', responses', observed'));
r_table.Properties.VariableNames = ["trial_number", "response", "observed"];
