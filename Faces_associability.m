%% Associability RL Model - Emotional Faces %%
% Adapted from STaylor's training scripts by CLavalley

clear
addpath('./lib/');

%% Setup the task configuration
% Task configuration:
%   probs:      starting probabilities, which will later be shuffled for 
%               each block
%   block_size: Length of a given block (in trials)
%   n_blocks:   Number of blocks for the task
%
% Each block represents a shuffling of the probabilities of winning a given
% arm.
game_config = struct(                           ...
    'probs', [0.7969, 0.1964, 0.9063, 0.0938, 0.9063, 0.0938, 0.6964; ...
              0.2031, 0.8036, 0.0938, 0.9063, 0.0938, 0.9063, 0.3036], ...
    'block_size', [64, 56, 32, 32, 32, 32, 56], ...
    'n_blocks', 7                               ...
);

%% Generate task from task configuration
% Generate the reward pattern for the task using the above game
% configuration.
task_rewards = gen_rewards_bernoulli_faces(game_config);

%% Initialize simulation parameters
% Setup a simulation with a given set of parameters.
parameters = struct('V0', 0.5, 'alpha', 0.7, 'beta', 3, 'eta', 0.5);

%% Simulate task with given parameters
% Simulate behavior with the given task reward pattern and assigned
% parameter values, using the associability model this time. Note how this
% script is identical to Example1.m, except `associability_model` is used
% here, and the `parameters` struct includes the extra parameter needed in
% the associability model, the 'eta' parameter.
[out] = associability_model(parameters, task_rewards);

%% Plot the simulated behavior
% Plot the simulated beliefs and game probabilities.
plot_2_arm_bandit_faces(game_config, task_rewards, out.sim_choices, out);

%% Belief Plots
% Below is another way to visualize beliefs over time.

plot_bandit_gradient_faces(game_config, task_rewards, out.sim_choices, out);

