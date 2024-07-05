% get params from hgf output
function param_table = params_tab(session, folder, output_folder)

directory = dir([folder '*' session '_output.mat']);

for i=1:size(directory,1)
    hgf_output(i) = load([folder directory(i).name]);
end

tab_size = [size(hgf_output,2) 9];
varTypes = ["string", "double", "double", "double", "double", "double", "double", "double", "double",];
varNames = ["subject", "omega_2", "omega_3", "beta_0", "beta_1", "beta_2", "beta_3", "beta_4", "zeta"];

param_table = table('Size', tab_size, 'VariableTypes', varTypes, 'VariableNames', varNames);
for m=1:size(hgf_output,2)
    param_table(m,1) = {extractBetween(directory(m).name, 1,"_")};
end

for j=1:size(hgf_output,2)
    for k=2:3
        param_table(j,k) = {hgf_output(j).x.p_prc.om(k)};
    end
end
for o=1:size(hgf_output,2)
    for k=4:9
        param_table(o,k) = {hgf_output(o).x.p_obs.p(k-3)};
    end
end


writetable(param_table, [output_folder '/param_table_' datestr(now, 'mm-dd-yyyy') '.csv'])

end