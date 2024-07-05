% Function for running the basic Rescorla-Wagner reinforcement learning 
% model.
% 
% Can assess the log-likelihood of a given parameter combination (when 
% provided both rewards and choices), or can simulate behavior for a given 
% parameter combination (when given only rewards and parameters).
%
% Parameters:
%   params:  struct array with fields:
%       .alpha: learning rate (0.0 - 1.0)
%       .beta:  exploration ( > 0.0)
%       .V0:    initial value for expected reward
%   rewards: (num_choices x T) matrix, where num_choices is number of 
%            choices and T is number of trials, where rewards(k, t) is the 
%            reward gained for choosing option k at time t.
%   choices: (1 x T) vector, where choices(t) is the selected choice at
%            timepoint t.
% 
% Return Values:
%   expected_reward:(num_choices x T) matrix, where expected_reward(k, t) 
%                   is the expected value for choice k at time t.
%   log_likelihood: Summed log-likelihood for the given params, rewards,
%                   and choices (typically used for fitting).
%   sim_choices:    (1 x T) vector, where sim_choices(t) is the selecetd
%                   choice at timepoint t, when simulating. NaN when not 
%                   simulating (when choices are provided)
%   P:              A (num_choices x T) matrix, where P(k, t) is the
%                   probability of choosing choice k at time t.
%
% Written by: Samuel Taylor, Laureate Institute for Brain Research (2022)

function [model_output] = RW_model(params, rewards, choices)
    % Log likelihood starts at 0.
    log_likelihood = 0;
    
    % For a N-choice decision task.
    N_CHOICES = size(rewards, 1);
    
    % Extract the total number of trials.
    T = length(rewards);
    
    % Represents the value function (number of choices X number of trials).
    % Has dimensions for both time and number of choices to keep track of
    % expceted reward over time.
    expected_reward = zeros(N_CHOICES, T);
    
    % Represents the probability distribution of making a particular choice
    % over time.
    P = zeros(N_CHOICES, T);
    
    % Set the initial values for the expected reward.
    expected_reward(:, 1) = params.V0;
    
    % If choices are passed in, do not run as simulation, but instead use
    % provided choices (typically used for fitting).
    if exist('choices', 'var')
        sim = false;
        sim_choices = NaN;
    % If choices are not passed in, run as a simulation instead, selecting
    % choices based on current value of expected reward at that timestep.
    else
        sim = true;
        sim_choices = zeros(1, T);
    end
    
    action_probabilities = zeros(1, T);
    
    % For each trial (timestep)...
    for t = 1:T
        % Transform the expected reward vector to a discrete probability 
        % distribution using a softmax function (which includes `beta` as 
        % an exploration parameter).
        P(:, t) = exp(params.beta * expected_reward(:, t)) / sum(exp(params.beta * expected_reward(1:N_CHOICES, t)));
        
        % If not simulating, get choice selected at t.
        if ~sim
            choice_at_t = choices(t);
        % If simulating, sample from P(:, t) instead
        else
            choice_at_t = randsample(1:N_CHOICES, 1, true, P(:, t));
            
            sim_choices(t) = choice_at_t;
        end
        
        % Store the probability of the chosen action being selected at this
        % timepoint.
        action_probabilities(t) = P(choice_at_t, t);
        
        % Compute the log-likelihood at this timestep
        % Represents a softmax with exploration parameter `beta`,
        % with a log function applied to the result.
        %
        % The below will look different from the typical softmax function.
        % Since a log function is applied to the entire softmax function,
        % some log properties can be exploited to replace the division with
        % a subtraction.
        ll_t = params.beta * expected_reward(choice_at_t, t) - log(sum(exp(params.beta * expected_reward(1:N_CHOICES, t))));
        
        % Given the above has a log applied to it, the log_likelihood can
        % be summed across trials. Without the log function, likelihoods
        % must be multiplied across trials, which is less numerically 
        % stable. 
        log_likelihood = log_likelihood + ll_t;
        
        % Prediction error is: reward recieved minus the expected reward
        % of the selected choice.  
        prediction_error = rewards(choice_at_t, t) - expected_reward(choice_at_t, t);
        
        % Copy previous expected reward values (to keep unchosen choices at
        % the same value from the previous timestep).
        expected_reward(:, t + 1) = expected_reward(:, t);
        
        % Update the expected reward of the selected choice.
        expected_reward(choice_at_t, t + 1) = expected_reward(choice_at_t, t) + params.alpha * prediction_error;
    end
    
    % Trims final value in expected reward matrix (is an extra value beyond
    % trials).
    expected_reward = expected_reward(:, 1:T);
    
    % Store model variables for returning.
    model_output.expected_reward = expected_reward;
    model_output.P = P;
    model_output.log_likelihood = log_likelihood;
    model_output.sim_choices = sim_choices;
    model_output.action_probabilities = action_probabilities;
end