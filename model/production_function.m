function Y_i=production_function(Q_s_i,alpha_bar_i,N_i,kappa_i,K_i,a_sg,beta_i,G_i,F_i,Y_m,G_m)
%UNTITLED9 Summary of this function goes here
%   Detailed explanation goes here

Y_i_=min(Q_s_i,min(N_i*1.5.*alpha_bar_i,K_i.*kappa_i));

F=size(a_sg,3);
G=size(a_sg,2);
fg=1;
for f=1:F
    for g=1:G
        Y_fg_(fg)=sum(Y_i_(G_i==g&F_i==f));
        A(:,fg)=a_sg(:,g,f)./mean(beta_i(G_i==g&F_i==f));
        C(g,fg)=1;
        fg=fg+1;
    end
end
A(isnan(A))=0;

m=zeros(G,1);
for g=1:G
    m(g)=sum(Y_m(G_m==g));
end

Y_fg=computeFeasibleOutput(Y_fg_',A,m,C)';

HC_fg=Y_fg./Y_fg_;

if any(HC_fg<1)
    fg=1;
    for f=1:F
        for g=1:G
            Y_i(G_i==g&F_i==f)=HC_fg(fg).*Y_i_(G_i==g&F_i==f);
            fg=fg+1;
        end
    end
else
    Y_i=Y_i_;
end
end

function x = computeFeasibleOutput(x_plan, A, m, C)
% computeFeasibleOutput Computes a feasible industry output vector given:
%
%   - Planned industry outputs x_plan (n_i x 1),
%   - A product-by-industry technological coefficients matrix A (n_p x n_i),
%     where A(i,j) is the amount of product i required per unit output in industry j.
%   - Product-level imports m (n_p x 1),
%   - A mapping matrix C (n_p x n_i) that aggregates industry outputs into products.
%
% The function finds x (n_i x 1) by solving the linear program:
%
%   maximize    sum(x)
%   subject to  x <= x_plan,
%               C*x + m >= A*x,  i.e., (C-A)*x >= -m,
%               x >= 0.
%
% This is reformulated for linprog (which minimizes) as:
%
%   minimize    -sum(x)
%   subject to  x <= x_plan,
%               - (C-A)*x <= m,
%               x >= 0.
%

% Number of industries and products
n_i = length(x_plan);   % number of industries
n_p = size(A, 1);       % number of products (from A)
% C is assumed to be n_p x n_i.

% Objective: maximize sum(x) is equivalent to minimizing -sum(x)
f = -ones(n_i, 1);

% Constraint 1: Industry outputs do not exceed planned outputs: x <= x_plan.
Aineq1 = eye(n_i);
bineq1 = x_plan;

% Constraint 2: Product-level feasibility:
% We require: C*x + m >= A*x, which is equivalent to:
%       (C-A)*x >= -m,
% or
%       - (C-A)*x <= m.
Aineq2 = - (C - A);
bineq2 = m;

% Combine inequality constraints.
Aineq = [Aineq1; Aineq2];
bineq = [bineq1; bineq2];

% Lower bounds: x >= 0.
lb = zeros(n_i, 1);

% Options for linprog (suppress output).
options = optimoptions('linprog','Display','none');

% Solve the linear program.
[x, ~, exitflag] = linprog(f, Aineq, bineq, [], [], lb, [], options);

if exitflag ~= 1
    error('Linear program did not converge.');
end

end

