-module(test_branch_timeout_exa).
-compile(export_all).
-compile(nowarn_export_all).

%% use this
%% generate:gen(test_branch_timeout_exa:role_s(),"tbranch_tout_s.erl").
%% generate:gen(test_branch_timeout_exa:role_r(),"tbranch_tout_r.erl").

role_s() ->
    {act, s_msg, 
        {branch, [
                {r_accept, endP},
                {r_reject, endP}
            ], aft, 3, {act, s_tout, endP}
        }
    }.


role_r(basic) -> 
    {act, r_msg,
        {act, s_accept, endP}
    };

role_r(act) ->
    {act, r_msg,
        {act, s_accept, endP,
         aft, 3, {act, r_tout, endP}
        }
    }.

role_r() ->
    {act, r_msg,
        {select, [
                {s_accept, endP},
                {s_reject, endP}
            ], aft, 3, {act, r_tout, endP}
        }
    }.

% role_r(delayable) -> 
%     {act, r_msg,
%         {delayable, 
%         }
%     }.
    
