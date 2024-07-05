function plot_bandit_gradient_faces(game_config, rewards, choices, model_outputs, missing_trials)
    figure;
    
    n_arms = height(game_config.probs);
    n_trials = length(choices);

    game_probs = zeros(n_arms, n_trials);
    
    arm_probs = game_config.probs;
    
    for block = 1:game_config.n_blocks
        start_idx = sum(game_config.block_size(:,1:block))-game_config.block_size(block)+1;
        final_idx = sum(game_config.block_size(:,1:block));

        game_probs(:, start_idx:final_idx) = repmat(arm_probs(:,block), 1, game_config.block_size(block));
    end
    if ~isempty(missing_trials)
       game_probs(:,missing_trials)=[];
    end

    grayscale = [0:1/64:1; 0:1/64:1; 0:1/64:1]';
    
    trials = 1:n_trials;
    arms = 1:n_arms;
    
    V_map = [1 - game_probs; 1 - model_outputs.P];
    
    imagesc(V_map); 
    colormap(grayscale);
    caxis([0, 1]);
    hold on;
    
    % A binary vector indicating whether a trial yielded a reward or not
    correct = rewards(sub2ind(size(rewards), choices, trials));
    
    good_choices = choices;
    good_choices(correct == 0) = NaN;
    bad_choices = choices;
    bad_choices(correct == 1) = NaN;
    
%     plot(choices + n_arms, '.', 'MarkerSize', 16, 'Color', [0, 0.4470, 0.7410]);

    % Plot correct choices as green dots
    plot(good_choices + n_arms, '.', 'MarkerSize', 16, 'Color', [0.4660, 0.6740, 0.1880]);
    % Plot incorrect choices as red dots
    plot(bad_choices + n_arms, '.', 'MarkerSize', 16, 'Color', [0.9350, 0.1780, 0.2840]);

    
    arm_labels = strcat({' Reward Probability for Arm '}, split(num2str(arms)));
    choice_labels = strcat({' Probability of Choosing Arm '}, split(num2str(arms)));
    labels = [arm_labels; choice_labels]';
    
    set(gca, 'YTick', 1:(2 * n_arms)), set(gca, 'YTickLabel', labels);
    
    
    hold off;
end