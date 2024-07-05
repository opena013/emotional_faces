% Generates rewards for N-armed bandit task using N bernoulli 
% distributions, that cycle on a block basis.
function [rewards] = gen_rewards_bernoulli_faces(game_config)
    n_arms = height(game_config.probs); 
    rewards = zeros(height(game_config.probs), sum(game_config.block_size)); 

    probs = game_config.probs;
    
    for block = 1:game_config.n_blocks
        for arm = 1:n_arms
            start_idx = sum(game_config.block_size(:,1:block))-game_config.block_size(block)+1;
            final_idx = sum(game_config.block_size(:,1:block));
            
            rewards(arm, start_idx:final_idx) = binornd(1, probs(arm, block), 1, game_config.block_size(block));
        end

    end
end