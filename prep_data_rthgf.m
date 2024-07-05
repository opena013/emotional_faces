function x = prep_data_rthgf(rtab)
% takes in response times from task and log transforms for the 
% tapas_logrt_linear_binary model

% r is a double array of response times (n x 1)
r = rtab;
r_ms = 1000*r;
r_ms = array2table(r_ms);

x = table;
for i = 1:height(r_ms)
    if i == 1 

        x.(i) = log(r_ms.(1)(i));
        x = renamevars(x, 'Var1', 'log rt');
    else 
        
        x.("log rt")(i) = log(r_ms.(1)(i));
    end
end    

x = table2array(x);
