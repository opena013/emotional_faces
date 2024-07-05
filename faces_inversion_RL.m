% Samuel Taylor and Ryan Smith, 2021

% Model inversion script
function [DCM] = faces_inversion_RL(DCM)

% MDP inversion using Variational Bayes
% FORMAT [DCM] = spm_dcm_mdp(DCM)

% If simulating - comment out section on line 196
% If not simulating - specify subject data file in this section 

%
% Expects:
%--------------------------------------------------------------------------
% DCM.MDP   % MDP structure specifying a generative model
% DCM.field % parameter (field) names to optimise
% DCM.U     % cell array of outcomes (stimuli)
% DCM.Y     % cell array of responses (action)
%
% Returns:
%--------------------------------------------------------------------------
% DCM.M     % generative model (DCM)
% DCM.Ep    % Conditional means (structure)
% DCM.Cp    % Conditional covariances
% DCM.F     % (negative) Free-energy bound on log evidence
% 
% This routine inverts (cell arrays of) trials specified in terms of the
% stimuli or outcomes and subsequent choices or responses. It first
% computes the prior expectations (and covariances) of the free parameters
% specified by DCM.field. These parameters are log scaling parameters that
% are applied to the fields of DCM.MDP. 
%
% If there is no learning implicit in multi-trial games, only unique trials
% (as specified by the stimuli), are used to generate (subjective)
% posteriors over choice or action. Otherwise, all trials are used in the
% order specified. The ensuing posterior probabilities over choices are
% used with the specified choices or actions to evaluate their log
% probability. This is used to optimise the MDP (hyper) parameters in
% DCM.field using variational Laplace (with numerical evaluation of the
% curvature).
%
%__________________________________________________________________________
% Copyright (C) 2005 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_dcm_mdp.m 7120 2017-06-20 11:30:30Z spm $

% OPTIONS
%--------------------------------------------------------------------------
ALL = false;

% prior expectations and covariance
%--------------------------------------------------------------------------
prior_variance = 2^-2;

for i = 1:length(DCM.field)
    field = DCM.field{i};
    try
        param = DCM.MDP.(field);
        param = double(~~param);
    catch
        param = 1;
    end
    if ALL
        pE.(field) = zeros(size(param));
        pC{i,i}    = diag(param);
    else
        if strcmp(field,'alpha')
            pE.(field) = log(2);               % in log-space (to keep positive)
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'prior_a')
            pE.(field) = log(.5);              % in log-space (to keep positive)
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'cr')
            pE.(field) = log(4);              % in log-space (to keep positive)
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'eta_win')
            pE.(field) = log(0.5/(1-0.5));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'eta_loss')
            pE.(field) = log(0.5/(1-0.5));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
       elseif strcmp(field,'omega')
            pE.(field) = log(0.75/(1-0.75));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
      elseif strcmp(field,'omega_win')
            pE.(field) = log(0.75/(1-0.75));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
     elseif strcmp(field,'omega_loss')
            pE.(field) = log(0.75/(1-0.75));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'eta_RL')
            pE.(field) = log(0.5/(1-0.5));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'beta_RL')
            pE.(field) = log(3);                % in log-space (to keep positive)
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'loss_aversion')
            pE.(field) = log(1);                % in log-space (to keep positive)
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'alpha_RL')
            pE.(field) = log(0.35/(1-0.35));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'alpha_win')
            pE.(field) = log(0.35/(1-0.35));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'alpha_loss')
            pE.(field) = log(0.35/(1-0.35));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        elseif strcmp(field,'V0')
            pE.(field) = log(0.5/(1-0.5));      % in logit-space - bounded between 0 and 1!
            pC{i,i}    = prior_variance;
        else
            pE.(field) = 0;      
            pC{i,i}    = prior_variance;
        end
    end
end

pC      = spm_cat(pC);

% model specification
%--------------------------------------------------------------------------
M.L     = @(P,M,U,Y)spm_mdp_L(P,M,U,Y);  % log-likelihood function
M.pE    = pE;                            % prior means (parameters)
M.pC    = pC;                            % prior variance (parameters)
M.mdp   = DCM.MDP;                       % MDP structure

% Variational Laplace
%--------------------------------------------------------------------------
[Ep,Cp,F] = spm_nlsi_Newton(M,DCM.U,DCM.Y);

% Store posterior densities and log evidnce (free energy)
%--------------------------------------------------------------------------
DCM.M   = M;
DCM.Ep  = Ep;
DCM.Cp  = Cp;
DCM.F   = F;


return

function L = spm_mdp_L(P,M,U,Y)
% log-likelihood function
% FORMAT L = spm_mdp_L(P,M,U,Y)
% P    - parameter structure
% M    - generative model
% U    - inputs
% Y    - observed repsonses
%__________________________________________________________________________

if ~isstruct(P); P = spm_unvec(P,M.pE); end

% multiply parameters in MDP
%--------------------------------------------------------------------------
mdp   = M.mdp;
field = fieldnames(M.pE);
for i = 1:length(field)
    if strcmp(field{i},'alpha')
        mdp.(field{i}) = exp(P.(field{i}));
    elseif strcmp(field{i},'prior_a')
        mdp.(field{i}) = exp(P.(field{i}));
    elseif strcmp(field{i},'cr')
        mdp.(field{i}) = exp(P.(field{i}));
    elseif strcmp(field{i},'eta_win')
        mdp.(field{i}) = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'eta_loss')
        mdp.(field{i}) = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'omega')
        mdp.(field{i}) = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'omega_win')
        mdp.(field{i}) = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'omega_loss')
        mdp.(field{i}) = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'eta_RL')
        mdp.parameters.eta = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'beta_RL')
        mdp.parameters.beta = exp(P.(field{i}));
    elseif strcmp(field{i},'loss_aversion')
        mdp.parameters.loss_aversion = exp(P.(field{i}));
    elseif strcmp(field{i},'alpha_RL')
        mdp.parameters.alpha = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'alpha_win')
        mdp.parameters.alpha_win = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'alpha_loss')
        mdp.parameters.alpha_loss = 1/(1+exp(-P.(field{i})));
    elseif strcmp(field{i},'V0')
        mdp.parameters.(field{i}) = 1/(1+exp(-P.(field{i})));
    else
        mdp.(field{i}) = exp(P.(field{i}));
    end
end


% discern whether learning is enabled - and identify unique trials if not
%--------------------------------------------------------------------------
if any(ismember(fieldnames(mdp),{'a','b','d','c','d','e'}))
    j = 1:numel(U);
    k = 1:numel(U);
else
    % find unique trials (up until the last outcome)
    %----------------------------------------------------------------------
    u       = spm_cat(U');
    [i,j,k] = unique(u(:,1:(end - 1)),'rows');
end

L = 0;
act_probs = [];
start_trial=1;
% For RW, fit low and high volatility separately
for idx_block = 1:mdp.NB
    task_rewards = zeros(2,mdp.TpB(idx_block));
    choices = zeros(1,mdp.TpB(idx_block));

    choices(1:mdp.TpB(idx_block)) = Y{1}(start_trial:start_trial+mdp.TpB(idx_block)-1);
    task_rewards(:,1:mdp.TpB(idx_block)) = [2*(U{1}(start_trial:start_trial+mdp.TpB(idx_block)-1))-1; % row1= hightone/sad, row2=hightone/angry
                    -(2*(U{1}(start_trial:start_trial+mdp.TpB(idx_block)-1))-1)];

    missed = find(isnan(choices));
    choices = choices(~isnan(choices));
    task_rewards = task_rewards(:,all(~isnan(task_rewards)));

    % solve MDP and accumulate log-likelihood
    %--------------------------------------------------------------------------
        if mdp.assoc
            MDP = assoc_model(mdp.parameters, task_rewards, choices);
        else
            MDP = RW_model_extended(mdp.parameters, task_rewards, choices);
        end
        
        for j = 1:mdp.TpB(idx_block) - length(missed)
              L = L + log(MDP.act_probs(j) + eps);
        end
        
        for i = 1:length(MDP.act_probs) % Get probability of true actions for each tria
            if MDP.P(MDP.choices(i),i) == max(MDP.P(:,i))
                acc(i) = 1;
            else
                acc(i) = 0;
            end
       end
          p_avg = sum(MDP.act_probs)/numel(MDP.act_probs);
          acc_avg = (sum(acc)/length(MDP.act_probs))*100;
%           fprintf('p_avg: %f \n',p_avg);
%           fprintf('acc_avg: %f \n',acc_avg);

end

clear('MDP')
    
