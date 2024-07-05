function plot_2_arm_bandit_faces(game_config, rewards, choices, model_outputs)
    n_arms = height(game_config.probs);
    n_trials = sum(game_config.block_size);

    game_probs = zeros(n_arms, n_trials);
    
    arm_probs = game_config.probs;
    
    for block = 1:game_config.n_blocks
        start_idx = sum(game_config.block_size(:,1:block))-game_config.block_size(block)+1;
        final_idx = sum(game_config.block_size(:,1:block));

        game_probs(:, start_idx:final_idx) = repmat(arm_probs(:,block), 1, game_config.block_size(block));
        
    end
    
    if(n_arms == 2)
        n_arms_adj = 1;
    else
        error(['`plot_2_arm_bandit` must be used with a configuration that has 2 arms (not ' num2str(n_arms) ').']);
    end
    
    if isfield(model_outputs, 'associability')
        subplot(2, 1, 2);
    end
    
    for arm = 1:n_arms_adj
        plot(game_probs(arm, :), 'Color', 'black', 'LineWidth', 2);
        hold on;
        plot(model_outputs.P(arm, :), 'Color', 'blue', 'LineWidth', 2);
    end
    
    trials = 1:n_trials;
    arms = 1:n_arms;
    
    ylim([-0.1, 1.1]);
    xlim([0, n_trials + 1]);
    
    % A binary vector indicating whether a trial yielded a reward or not
    correct = rewards(sub2ind(size(rewards), choices, trials));
    
    good_choices = -choices + 3;
    good_choices(correct == 0) = NaN;
    bad_choices = -choices + 3;
    bad_choices(correct == 1) = NaN;
    
    % Plot correct choices as green dots
    plot(good_choices - 1, '.', 'MarkerSize', 16, 'Color', [0.4660, 0.6740, 0.1880]);
    % Plot incorrect choices as red dots
    plot(bad_choices - 1, '.', 'MarkerSize', 16, 'Color', [0.9350, 0.1780, 0.2840]);
    
    legend({'Probability of Winning in Arm 1', 'Probability of Choosing Arm 1', 'Winning Choices', 'Losing Choices'},'Location','southoutside')
    
    xlabel('Trial number');
    ylabel('Probability');
    hold off;
    
    if isfield(model_outputs, 'associability')
        subplot(2, 1, 1);

        for arm = 1:n_arms
            plot(model_outputs.associability(arm, :), 'LineWidth', 2);
            hold on;
        end
        
        legend({'Associability of Arm 1', 'Associability of Arm 2'},'Location','southoutside')
        hold off;
    end
end