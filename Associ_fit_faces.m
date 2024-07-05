% Associability RL Model - Emotional Faces
clear

%% Set parameters 
if isunix
    root='/media/labs';
    subject = getenv("SUBJECT");
    in_dir = getenv("INPUT_DIR");
    result_dir = getenv("RESULTS");
    assoc = strcmp(getenv('ASSOC_MODEL'), 'true');
    splt_learn = strcmp(getenv('SPLIT_MODEL'), 'true');
    cb = getenv("COUNTERBALANCE");
    run = getenv("RUN");
    p_r = getenv("P_OR_R");
elseif ispc
    root='L:';
    subject = 'A1CFMY4CEYOM8Y';
    in_dir = [root '/NPC/DataSink/StimTool_Online/WBMTURK_Emotional_FacesCB2']; 
    result_dir = [root ... %change the output directory
        '/rsmith/lab-members/clavalley/studies/development/wellbeing/faces/hgf_output/50'];
    assoc = true;
    splt_learn = false;
    cb = '2'; %counterbalance order
    run = '1';
    p_r = 'p'; %p=predictions, r=responses
end

addpath('./associability/lib/');
addpath([root '/rsmith/all-studies/util/spm12/']);
addpath([root '/rsmith/all-studies/util/spm12/toolbox/DEM/']);

RL = true;

%% Initialize parameters
    V0 = 0.5;
    alpha_RL =  0.35; 
    alpha_win =  0.35;
    alpha_loss =  0.35;
    beta_RL = 3;
    loss_aversion = 1;
    eta_RL = .5; %if associability

%% Set game configuration
if strcmp(cb, '1')
    cb_name = [];
else 
    cb_name = '_CB';
end
if strcmp(p_r, 'p')
    ecode=12;
elseif strcmp(p_r, 'r')
    ecode=7;
end

% Note: in the retest schedules, "prob_hightone_sad" is actually the
% probability of the hightone/angry association
schedule = readtable([root '/rsmith/wellbeing/tasks/EmotionalFaces/schedules/faces_schedule' cb_name '-R' run '.csv']);

probs=[];
sborp=[];
block_sz=[];
for i = 1:length(unique(schedule.block_num, "stable"))
    probs = [probs unique(schedule(schedule.block_num==i,:).prob_hightone_sad)'];
    sborp = [sborp 1-unique(schedule(schedule.block_num==i,:).prob_hightone_sad)'];
end
game_probs = vertcat(probs,sborp);
if assoc 
    block_sz = 200;
else
    block_sz = [100, 100];
end
NB = length(block_sz);

game_config = struct(                           ...
     'probs', game_probs, ...
     'block_size', block_sz, ...
     'n_blocks', NB                              ...
 );

%% Add Subj Data (Parse the data files)
    directory = dir(in_dir);
    index_array = find(arrayfun(@(n) contains(directory(n).name, ['emotional_faces_v2_' subject]),1:numel(directory)));

    file = [in_dir '/' directory(index_array).name];
    opts = detectImportOptions(file);
    opts = setvartype(opts, {'trial', 'event_type', 'absolute_time', 'response_time'}, 'double');
    subdat = readtable(file, opts); %subject data 
    
    [responses, subtab] = get_responses(subdat, p_r);

    % Parse observations and actions
    sub.o = responses.observed'; %1-hightone/sad, 0-hightone/angry
    sub.u = responses.response'; %1-hightone/sad, 0-hightone/angry

    sub.u = abs(sub.u-1)+1;

  if assoc == true
      MDP.parameters = struct('V0', V0, 'alpha', alpha_RL, 'beta', beta_RL,'eta', eta_RL);
  else
      MDP.parameters = struct('V0', V0, 'alpha', alpha_RL, 'beta', beta_RL, 'alpha_win', alpha_win, 'alpha_loss', alpha_loss, 'loss_aversion', loss_aversion,'split_learning',splt_learn);
  end
    
 MDP.BlockProbs = game_probs; % Block probabilities
 MDP.TpB        = block_sz;        % trials per block
 MDP.NB         = NB;         % number of blocks
 %MDP.prior_a    = prior_a;    % prior_a
 MDP.RL         = RL;
 MDP.assoc      = assoc;

DCM.MDP    = MDP; 
  if assoc == true
      DCM.field  = {'V0' 'alpha_RL' 'beta_RL','eta_RL'}; % Parameter field
  else
      if splt_learn == true
          DCM.field  = {'V0' 'alpha_win' 'alpha_loss' 'beta_RL'}; % Parameter field, 'loss_aversion'
      else
          DCM.field  = {'V0' 'alpha_RL' 'beta_RL'}; % Parameter field
      end
  end

    DCM.U      = {sub.o};              % trial specification (stimuli)
    DCM.Y      = {sub.u};              % responses (action)

    DCM        = faces_inversion_RL(DCM); 

    
 %% 6.3 Check deviation of prior and posterior means & posterior covariance:
    %==========================================================================

    %--------------------------------------------------------------------------
    % re-transform values and compare prior with posterior estimates
    %--------------------------------------------------------------------------
    field = fieldnames(DCM.M.pE);
    for i = 1:length(field)
        if strcmp(field{i},'alpha_RL')
            prior(i) = 1/(1+exp(-DCM.M.pE.(field{i})));
            posterior(i) = 1/(1+exp(-DCM.Ep.(field{i}))); 
        elseif strcmp(field{i},'eta_RL')
            prior(i) = 1/(1+exp(-DCM.M.pE.(field{i})));
            posterior(i) = 1/(1+exp(-DCM.Ep.(field{i})));
        elseif strcmp(field{i},'alpha_win')
            prior(i) = 1/(1+exp(-DCM.M.pE.(field{i})));
            posterior(i) = 1/(1+exp(-DCM.Ep.(field{i})));
        elseif strcmp(field{i},'alpha_loss')
            prior(i) = 1/(1+exp(-DCM.M.pE.(field{i})));
            posterior(i) = 1/(1+exp(-DCM.Ep.(field{i})));
        elseif strcmp(field{i},'V0')
            prior(i) = 1/(1+exp(-DCM.M.pE.(field{i})));
            posterior(i) = 1/(1+exp(-DCM.Ep.(field{i}))); 
        else
            prior(i) = exp(DCM.M.pE.(field{i}));
            posterior(i) = exp(DCM.Ep.(field{i}));
        end
    end

    all_MDPs = [];
    

act_probs = [];
all_MDPs = [];
start_trial=1;

% NB=1 for associability, NB=2 for RW
for idx_block = 1:NB

task_rewards = zeros(2,MDP.TpB(idx_block));
choices = zeros(1,MDP.TpB(idx_block));

choices(1:MDP.TpB(idx_block)) = DCM.Y{1}(start_trial:start_trial+MDP.TpB(idx_block)-1);
task_rewards(:,1:MDP.TpB(idx_block)) = [2*(DCM.U{1}(start_trial:start_trial+MDP.TpB(idx_block)-1))-1; % row1= hightone/angry, row2=hightone/sad
    -(2*(DCM.U{1}(start_trial:start_trial+MDP.TpB(idx_block)-1))-1)];

missed = find(isnan(choices));

choices = choices(~isnan(choices));
task_rewards = task_rewards(:,all(~isnan(task_rewards)));


if splt_learn == true
   params = struct('V0', posterior(1), 'alpha_win', posterior(2), 'alpha_loss', posterior(3), 'beta', posterior(4), 'split_learning',splt_learn); %'loss_aversion', posterior(5),
   MDPs = RW_model_extended(params, task_rewards, choices);
elseif assoc == true
   params = struct('V0', posterior(1), 'alpha', posterior(2), 'beta', posterior(3),'eta',posterior(4));
   MDPs = assoc_model(params, task_rewards, choices);
else
   params = struct('V0', posterior(1), 'alpha', posterior(2), 'beta', posterior(3),'split_learning',splt_learn);
   MDPs = RW_model_extended(params, task_rewards, choices);
end

if assoc && ispc
   game_config.probs = [.8 .2];
% Plot the simulated beliefs and game probabilities.
   plot_2_arm_bandit(game_config, task_rewards, choices, MDPs);
end
% Belief Plots
%plot_bandit_gradient(game_config, task_rewards, choices, MDPs);

        
        
for j = 1:MDP.TpB(idx_block)-length(missed)
  act_probs(j) = MDPs.act_probs(j);
end
        
for i = 1:length(MDPs.act_probs) % Get probability of true actions for each trial
   if MDPs.P(MDPs.choices(i),i) == max(MDPs.P(:,i))
     acc(i) = 1;
   else
     acc(i) = 0;
   end
end
        
all_MDPs = [all_MDPs; MDPs'];
avg_act(idx_block) = sum(act_probs)/numel(act_probs);
model_acc(idx_block) = (sum(acc)/length(acc));

start_trial = start_trial + MDP.TpB(idx_block);

clear MDPs;
clear act_probs
clear acc
end
  
 
   p_acc_avg = [avg_act model_acc];
   

    % Return input file name, prior, posterior, output DCM structure, and
    % list of MDPs across task using fitted posterior values
    if assoc
        model = 'assoc';
    elseif RL && ~assoc && ~splt_learn
        model = 'rl';
    elseif RL && splt_learn 
        model = 'split-lr';
    end

    FinalResults = [{file} prior posterior DCM all_MDPs p_acc_avg];
   

fittable.subject = subject;
fittable.run = run;
fittable.counterbalance = cb;
if splt_learn
    fittable.V0 = posterior(1);   
    fittable.alpha_win = posterior(2);
    fittable.alpha_loss = posterior(3);
    fittable.beta_RL = posterior(4);
    fittable.avg_act = p_acc_avg(1);
    fittable.model_acc = p_acc_avg(2);
elseif assoc
    fittable.V0 = posterior(1);   
    fittable.alpha_RL = posterior(2);
    fittable.beta_RL = posterior(3);
    fittable.eta_RL = posterior(4);
    fittable.avg_act = p_acc_avg(1);
    fittable.model_acc = p_acc_avg(2);

else
    fittable.V0 = posterior(1);   
    fittable.alpha_RL = posterior(2);
    fittable.beta_RL = posterior(3);
    fittable.avg_act = p_acc_avg(1);
    fittable.model_acc = p_acc_avg(2);
end

if size(struct2table(fittable),2) <=3
    return
end

save([result_dir '/output_' model '_' subject '_T' run '_' p_r '.mat'], 'FinalResults')    
writetable(struct2table(fittable), [result_dir '/faces_' subject '_T' run '_' model '_' p_r '.csv'])