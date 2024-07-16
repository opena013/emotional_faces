%% HGF Wrapper Function, 2023

clear all 
dbstop if error
if ispc
    root = 'L:/';    
    run = '1';   % MTurk Session 1,2,3
    res_dir = 'L:/rsmith/lab-members/osanchez/emotional_faces/Output_prolific';
    rt_model = false;
    p_or_r = 'p'; %prediction or responses (for binary hgf) - p=prediction, r=responses
    %cb = '2'; %counterbalance order
    show_plot = true;
    % for experiment mode, specify if mturk, stimtool, or inperson
    experiment_mode = "prolific";
    if experiment_mode == "inperson"
        subject = 'BW281';   % inperson Subject ID
    elseif experiment_mode == "mturk"
        subject = 'AM0JKZVOEOTMA';   % Mturk Subject ID (others AM0JKZVOEOTMA, A1IZ4NX41GKU4X, A1Q7VWUBIJOK17)
    elseif experiment_mode == "prolific"
        subject = '60cee4ec871f36088fe20ff3';
    end

elseif isunix 
    root = '/media/labs/';
    subject = getenv('SUBJECT'); 
    run = getenv('RUN');   
    res_dir = getenv('RESULTS');
    rt_model = strcmp(getenv('MODEL'), 'true');
    p_or_r = getenv('PREDICTION'); 
    %cb = getenv('COUNTERBALANCE');
    experiment_mode = getenv('EXPERIMENT');
    show_plot = false;
end



addpath('./HGF/')


if run==1 || run=='1'
    str_run=[];
else
    str_run = num2str(run);
end

if (experiment_mode == "mturk")
    file_path = [root 'NPC/DataSink/StimTool_Online/WBMTURK_Emotional_FacesCB' cb];
    directory = dir(file_path);
    index_array = find(arrayfun(@(n) contains(directory(n).name, ['emotional_faces_v2_' subject]),1:numel(directory)));
elseif (experiment_mode == "inperson")
    file_path = [root 'rsmith/wellbeing/data/raw/sub-' subject];
    directory = dir(file_path);
    index_array = find(arrayfun(@(n) contains(directory(n).name, {'EF_R2', 'EF_R1'}),1:numel(directory)));
elseif (experiment_mode == "prolific")
    file_paths = {[root 'NPC/DataSink/StimTool_Online/WB_Emotional_Faces'], [root 'NPC/DataSink/StimTool_Online/WB_Emotional_Faces_CB']};
    for k = 1:length(file_paths)
        file_path = file_paths{k};
        directory = dir(file_path);
        % sort by date
        dates = datetime({directory.date}, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
        % Sort the dates and get the sorted indices
        [~, sortedIndices] = sort(dates);
        % Use the sorted indices to sort the structure array
        directory = directory(sortedIndices);
        index_array = find(arrayfun(@(n) contains(directory(n).name, ['emotional_faces_v2_' subject]),1:numel(directory)));
        % check if this person's file is in the directory
        if ~isempty(index_array)
            break;
        end
    end
    if strcmp(file_path, [root 'NPC/DataSink/StimTool_Online/WB_Emotional_Faces']); cb = '1'; else; cb='2';end

end

% initialize has_practice_effects to false, tracking if this participant's
% first complete behavioral file came after they played the task a little
% bit
has_practice_effects = false;
if length(index_array) > 1
    disp("WARNING, MULTIPLE BEHAVIORAL FILES FOUND FOR THIS ID. USING FIRST ONE")
end





for k=1:length(index_array)
    raw = readtable([file_path '/' directory(index_array(k)).name]);
    if any(cellfun(@(x) isequal(x, 'MAIN'), raw.trial_type)) && (max(raw.trial)<199)
        has_practice_effects = true;
    end
    
    if max(raw.trial)<199
        run_script=0;
        continue;
    else 
        run_script=1;
    end
    if experiment_mode == "inperson"
        raw.trial = raw.trial_number;
    end

    try
        
        if run_script==1

            [x, file_table] = hgf_function(str_run, raw, rt_model, p_or_r, cb, experiment_mode);
            if show_plot
                tapas_hgf_binary_plotTraj(x)
            end
            if experiment_mode == "mturk" | experiment_mode == "prolific"
                resp_index = find(file_table.event_type==6)+1;
                resp_table = file_table(resp_index,:);
                predict_index = find(file_table.event_type==12);
                predict_table = file_table(predict_index,:);
                predict_table.trial_number = predict_table.trial;
                resp_table.trial_number = resp_table.trial;
            elseif experiment_mode == "inperson"
                % note that these are zero indexed
                resp_index = find(file_table.event_code==8);
                resp_table = file_table(resp_index,:);
                predict_index = find(file_table.event_code==6);
                predict_table = file_table(predict_index,:);
                for i=resp_table.trial_number'
                    trial_type = file_table(file_table.trial_number == i & file_table.event_code == 11,:).trial_type(1);
                    resp_table(resp_table.trial_number == i, :).trial_type = trial_type;
                end
                for i=predict_table.trial_number'
                    trial_type = file_table(file_table.trial_number == i & file_table.event_code == 11,:).trial_type(1);
                    predict_table(predict_table.trial_number == i, :).trial_type = trial_type;
                end

            end
            if rt_model
                model = 'rt-HGF';

                sub_table.ID = subject;
                sub_table.run = run;
                sub_table.counterbalance = cb;
                % MODEL-BASED
                sub_table.omega_2 = x.p_prc.om(2);
                sub_table.omega_3 = x.p_prc.om(3);
                sub_table.beta_0 = x.p_obs.be0;
                sub_table.beta_1 = x.p_obs.be1;
                sub_table.beta_2 = x.p_obs.be2;
                sub_table.beta_3 = x.p_obs.be3;
                sub_table.beta_4 = x.p_obs.be4;
                sub_table.zeta = x.p_obs.ze;
                sub_table.AIC = x.optim.AIC;
                sub_table.LME = x.optim.LME;

            else
                model = 'binary-HGF';

                sub_table.ID = subject;
                sub_table.run = run;
                % MODEL-BASED
                sub_table.omega_2 = x.p_prc.om(2);
                sub_table.omega_3 = x.p_prc.om(3);
                %sub_table.zeta = x.p_obs.ze;  %rho?
                sub_table.AIC = x.optim.AIC;
                sub_table.LME = x.optim.LME;      
                sub_table.avg_act = sum(x.optim.action_probs(~isnan(x.optim.action_probs)))/length(x.optim.action_probs(~isnan(x.optim.action_probs)));
                sub_table.model_acc = sum(x.optim.action_probs > 0.5)/length(x.optim.action_probs(~isnan(x.optim.action_probs)));
                sub_table.variance = var(x.optim.action_probs(~isnan(x.optim.action_probs)));
            end
            % MODEL FREE
            sub_table.has_practice_effects = has_practice_effects;
            sub_table.model = model;
            sub_table.p_or_r = p_or_r;
            sub_table.p_trials = size(predict_table,1);
            sub_table.r_trials = size(resp_table,1);
            sub_table.cor_trials =  sum(strcmp(resp_table.result, 'correct'));
            
            % Add schedule
            schedule = readtable('L:/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/schedules/emotional_faces_CB1_schedule_claire.csv');
            schedule_cb = readtable('L:/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/schedules/emotional_faces_CB2_schedule_claire.csv');
            if cb == "1" 
                resp_table.intensity = schedule.intensity;
                resp_table.expectation = schedule.expectation;
                resp_table.prob_hightone_sad = schedule.prob_hightone_sad;
            else
                resp_table.intensity = schedule_cb.intensity;
                resp_table.expectation = schedule_cb.expectation;
                resp_table.prob_hightone_sad = schedule_cb.prob_hightone_sad;
            end

            sub_table.r_incor_sad_high =  sum(strcmp(resp_table(strcmp(resp_table.result, 'incorrect'),:).trial_type, 'sad_high'));
            sub_table.r_incor_sad_low =  sum(strcmp(resp_table(strcmp(resp_table.result, 'incorrect'),:).trial_type, 'sad_low'));
            sub_table.r_incor_angry_high =  sum(strcmp(resp_table(strcmp(resp_table.result, 'incorrect'),:).trial_type, 'angry_high'));
            sub_table.r_incor_angry_low =  sum(strcmp(resp_table(strcmp(resp_table.result, 'incorrect'),:).trial_type, 'angry_low'));

            % accuracy x intensity
            low_per = sum(strcmp(resp_table.intensity, 'low'));
            high_per = sum(strcmp(resp_table.intensity, 'high'));
            sub_table.corr_low =  sum(strcmp(resp_table.result, 'correct') & strcmp(resp_table.intensity, 'low'))/low_per;
            sub_table.corr_high = sum(strcmp(resp_table.result, 'correct') & strcmp(resp_table.intensity, 'high'))/high_per;
           
            % accuracy x expectation 
            exp = sum(resp_table.expectation == 1);
            unexp = sum(resp_table.expectation == 0);
            sub_table.corr_exp = sum(resp_table.expectation == 1 & strcmp(resp_table.result, 'correct'))/exp;
            sub_table.corr_unexp = sum(resp_table.expectation == 0 & strcmp(resp_table.result, 'correct'))/unexp;

            %response_time x expectation
            resp_table.response_time = str2double(resp_table.response_time);
            sub_table.resp_time_exp = sum(resp_table.response_time(resp_table.expectation == 1))/exp;
            sub_table.resp_time_unexp = sum(resp_table.response_time(resp_table.expectation == 0))/unexp;

            %response time x intensity
            sub_table.resp_time_high = sum(resp_table.response_time(strcmp(resp_table.intensity, 'high')))/high_per;
            sub_table.resp_time_low = sum(resp_table.response_time(strcmp(resp_table.intensity, 'low')))/low_per;

            sub_table.p_incor_sad_high =  sum(strcmp(predict_table(strcmp(predict_table.result, 'incorrect'),:).trial_type, 'sad_high'));
            sub_table.p_incor_sad_low =  sum(strcmp(predict_table(strcmp(predict_table.result, 'incorrect'),:).trial_type, 'sad_low'));
            sub_table.p_incor_angry_high =  sum(strcmp(predict_table(strcmp(predict_table.result, 'incorrect'),:).trial_type, 'angry_high'));
            sub_table.p_incor_angry_low =  sum(strcmp(predict_table(strcmp(predict_table.result, 'incorrect'),:).trial_type, 'angry_low'));
            

            if experiment_mode == "inperson"
                % register missed trials and trial_type. Note this is 1-indexed
                for i=predict_table.trial_number'
                    if (~any(resp_table.trial_number == i))
                        missing_trial_type{i+1} = predict_table.trial_type{i+1};
                    else
                        missing_trial_type{i+1} = nan;
                    end
                end
            end

            if experiment_mode == "mturk" | experiment_mode=="prolific"
                missing_trial_type = resp_table.trial_type(strcmp(resp_table.result, 'too slow sad') | strcmp(resp_table.result, 'too slow angry'));
            end
            sub_table.r_missed_sad_high = sum(cellfun(@(x) strcmp(x, 'sad_high'), missing_trial_type));
            sub_table.r_missed_sad_low = sum(cellfun(@(x) strcmp(x, 'sad_low'), missing_trial_type));
            sub_table.r_missed_angry_high = sum(cellfun(@(x) strcmp(x, 'angry_high'), missing_trial_type));
            sub_table.r_missed_angry_low = sum(cellfun(@(x) strcmp(x, 'angry_low'), missing_trial_type));

         
           save([res_dir '/output_' model '_' 'cb' cb '_' subject], 'sub_table');
           writetable(struct2table(sub_table), [res_dir '/faces_' subject '_T' num2str(run) '_cb' cb '_' model '_' p_or_r '_fits.csv'])
           saveas(gcf, [res_dir '/faces_' subject '_T' num2str(run) '_cb' cb '_' model '_' p_or_r '_image.png']);
           clear all; close all;
           break; % break out of for loop because full file ran without error
        end
    catch e
        fprintf("Behavioral file caused script to error for %s\n", subject);
        disp(e);
        clear all; close all;
    end
end
%tapas_hgf_binary_plotTraj(x)
