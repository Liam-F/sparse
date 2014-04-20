% Setting random state to get constant answers
randn('state',23432);
rand('state',3454);


%%%%%%%%%%%%%%%%%%% From File %%%%%%%%%%%%%%%%%%
fI = importdata('FPSEOnlyData');
fR = importdata('FPSESecuritiesData');
% fI = fI(1:100,1);
% fR = fR(1:100,1:50
% fR = fR(:,10:20);
T = size(fI, 1) - 1;
totalassets = size(fR,2);

R = [];
for i = 1:totalassets
    
    returns = [];
    
    for curr = 2:(T+1)
        returns = [returns, fR(curr, i) / fR(curr-1, i)];
    end
    
    R = [R; returns];
end

I = [];
for curr = 2:(T+1)
    I = [I; fI(curr) / fI(curr-1)];
end

% Calculating returns for Index
I = mean(R)';






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Tracking error of Portfolio Subset %%%%%%%
%Initialize

Beta = 0.8;
k = 1;
C = 1/sqrt(totalassets) + k*(1-1/sqrt(totalassets))/(10*sqrt(totalassets));
divcoef = 1 / (T*(1-Beta));

delta = 1.0;

subset_n = 30;
cvx_n = totalassets;
cvx_R = R(1:cvx_n,:);
cvx_I = I;


% % % % % % % % % % % Variables % % % % % % % % % % 
% This array will contain the subset_n of stocks chosen from the index
%   Avaiable : are the stocks that haven't been added to the set
%   Values   : are the values obtained when computing our regression function
%              after adding our selected stock
pimats_a          = zeros(cvx_n);
chosen_a          = logical(zeros(1,cvx_n));
chosen_order_a    = [];
chosen_error_a    = [];

available_a   = linspace(1,cvx_n,cvx_n);

for i=1:cvx_n
    
    available_a_n = size(available_a,2)
    values      = zeros(1,available_a_n);
    
    tic
    for j=1:available_a_n
        
        selected = available_a(j);
        chosen_a(selected) = true;
        
        curr_R = cvx_R(chosen_a,:);
        
        if j == 1 || j == floor(available_a_n/2)
            disp([i, j, selected, find(chosen_a==1)]);
        end
        
        % Absolute Value Optimization (Abs)
        cvx_begin quiet
            variable z_a(T)
            variable pimat_a(i)
            minimize( (1/T) * sumabs(cvx_I, curr_R,pimat_a) )

            subject to
                pimat_a >= 0
                sum(pimat_a) == 1
        cvx_end
        
        pimats_a(chosen_a,i)= pimat_a;
        values(j) = sum(abs(I - curr_R'*pimat_a));
        chosen_a(selected) = false;
    end
    toc
    
    [values, sorted_index] = sort(values);
    optimal = sorted_index(1);
    optimal_index = available_a(optimal)
    
    chosen_a(optimal_index) = true;
    chosen_order_a = [chosen_order_a optimal_index];
    chosen_error_a = [chosen_error_a, values(1)];
    
    % Removing the index from the available stock subset
    available_a(optimal)=[];
    
end








% % CVX to find optimal value for NCCVAR
% cvx_begin quiet
%     variable z_n(T)
%     variable Alpha_n
%     variable pimat_n(cvx_n)
%     minimize( Alpha_n + divcoef * sum(z_n) )
%     subject to
%         z_n >= 0
%         z_n - abs(cvx_I - cvx_R'*pimat_n) + Alpha_n >= 0
% 
%         % QUESTION: This constrain ensures that less assets have a position of 0?
%         % (Also performs better without this constrain)
% %         norm(pimat_n) <= C
%         pimat_n >= 0
%         sum(pimat_n) == 1
% cvx_end
% 
% cvx_begin quiet
%     variable z_c(T)
%     variable Alpha_c
%     variable pimat_c(cvx_n)
%     minimize( Alpha_c + divcoef * sum(z_c) )
%     subject to
%         z_c >= 0
%         z_c - (cvx_I - transpose(cvx_R)*pimat_c) + Alpha_c >= 0
%         pimat_c >= 0
%         sum(pimat_c) == 1
% 
%         % QUESTION: Should this norm constraint be in CVAR as well?
%         % Note: This performs better without this constraint
% %         norm(pimat_c) <= C
% cvx_end
% 
% % CVX to find optimal value for Tracking Error Abs
% cvx_begin quiet
%     variable z_a(T)
%     variable pimat_a(cvx_n)
%     minimize( (1/T) * sum(z_a) )
%     subject to
%         z_a >= 0
% %         transpose(z_c)*z_c <= power(C,2)
%         z_a - abs(cvx_I - transpose(cvx_R)*pimat_a) >= 0
%         pimat_a >= 0
%         sum(pimat_a) == 1
%         % QUESTION: Should this norm constraint be in CVAR as well?
% %         norm(pimat_a) <= C
% cvx_end
% 
% % CVX to find optimal value for Lasso
% cvx_begin quiet
%     variable z_l(T)
%     variable pimat_l(totalassets)
%     
%     minimize(sum(power(I - transpose(R)*pimat_l, 2)) + delta*sum(pimat_l))
%     
%     subject to
%         sum(pimat_l) <= 1
%         pimat_l >= 0
% cvx_end
% 
% pimats_cvx = [pimat_n pimat_c pimat_a ];
% 
% % Calculating Tracking Error
% cvx_Ret = [ 
%             abs(I - cvx_R' * pimat_n) ...
%             abs(I - cvx_R' * pimat_c) ...
%             abs(I - cvx_R' * pimat_a) ...
%             abs(I - R' * pimat_l)
%           ]
% 
% % Tracking Errors
% te = sum(cvx_Ret)